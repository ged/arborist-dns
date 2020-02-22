# -*- ruby -*-
#encoding: utf-8

require 'set'
require 'whois'
require 'whois-parser'
require 'resolv'

require 'arborist/monitor'
require 'arborist/mixins'
require 'arborist/dns'

using Arborist::TimeRefinements


# DNS monitor types for Arborist
module Arborist::Monitor::DNS


	# Domain name monitor
	#
	# Examples:
	#
	#     # monitors/dns_checks.rb
	#     require 'arborist/mixins'
	#     require 'arborist/monitor'
	#     require 'arborist/monitor/dns'
	#
	#     using Arborist::TimeRefinements
	#
	#     Arborist::Monitor 'check for domain expiration', :domainnames do
	#         every 23.hours
	#         match type: 'dnsdomain'
	#         exec Arborist::Monitor::DNS::Domain
	#     end
	class Domain
		extend Loggability

		# The default options for running the monitor
		DEFAULT_OPTIONS  = {
			timeout: 15.seconds
		}

		# The list of node properties to fetch for this monitor
		USED_PROPERTIES = %i[ name ].freeze


		# Use the Arborist-DNS logger
		log_to :arborist_dns


		### Instantiate a DNS monitor and run it for the specified +nodes+.
		def self::run( nodes )
			self.new.run( nodes )
		end


		### Return the properties used by this monitor.
		def self::node_properties
			return USED_PROPERTIES
		end


		### Create a new DNS monitor with the given +options+.
		def initialize( options=DEFAULT_OPTIONS )
			options = DEFAULT_OPTIONS.merge( options || {} )

			options.each do |name, value|
				self.public_send( "#{name}=", value )
			end

			@client = Whois::Client.new
		end


		######
		public
		######

		# The timeout for connecting, in seconds.
		attr_accessor :timeout

		# The Whois client object
		attr_accessor :client


		### Return a clone of this object with its timeout set to +new_timeout+.
		def with_timeout( new_timeout )
			copy = self.clone
			copy.timeout = new_timeout
			return copy
		end


		### Run the domain check for each of the specified Hash of +nodes+ and return a Hash of
		### updates for them based on their DNS domain record's status.
		def run( nodes )
			self.log.debug "Got nodes to check with %p: %p" % [ self, nodes ]

			records = nodes.each_with_object( {} ) do |(identifier, node), hash|
				self.log.debug "Looking up whois info for %p (%p)" % [ identifier, node ]
				hash[ identifier ] = self.client.lookup( node['name'] )
			end

			return records.each_with_object( {} ) do |(identifier, record), hash|
				parser = record.parser
				hash[ identifier ] = self.parse_record( parser, identifier )
			end

		end


		### Use the provided +parser+ to build an update for the node with the specified
		### +identifier+ and return it as a Hash.
		def parse_record( parser, identifier )
			expires = parser.expires_on if parser.property_any_supported?( :expires_on )

			if !parser.registered?
				return { error: 'Not registered.' }
			elsif expires && expires <= Time.now
				return { error: "Expired on #{expires}" }
			end

			return Whois::Parser::PROPERTIES.each_with_object({}) do |prop, data|
				next unless parser.property_any_supported?( prop )

				val = parser.public_send( prop )

				case prop
				when :nameservers
					data[ 'nameservers' ] = val.map( &:name )
				when :available?, :registered?
					data[ prop.to_s[0..-2] ] = val
				when :registrant_contacts, :admin_contacts, :technical_contacts
					data[ prop ] = val.map do |contact|
						"%s <%s>" % [ contact.name, contact.email ]
					end
				when :status
					data[ prop ] = val.map( &:to_s )
				else
					data[ prop ] = val.to_s
				end
			end
		rescue Whois::ParserError, NoMethodError => err
			msg = "%p while parsing record for %s: %s" %
				[ err.class, identifier, err.message ]
			self.log.error( msg )
			self.log.debug { err.backtrace.join("\n  ") }

			return { warning: "Record fetched, but the record could not be parsed." }
		end

	end # class Domain



	class Records
		extend Loggability

		# The default options for running the monitor
		DEFAULT_OPTIONS  = {
			timeout: 5.seconds
		}

		# The list of node properties to fetch for this monitor
		USED_PROPERTIES = %i[ name record_type values ].freeze


		# Use the Arborist-DNS logger
		log_to :arborist_dns


		### Instantiate a DNS monitor and run it for the specified +nodes+.
		def self::run( nodes )
			self.new.run( nodes )
		end


		### Return the properties used by this monitor.
		def self::node_properties
			return USED_PROPERTIES
		end


		### Create a new DNS monitor with the given +options+.
		def initialize( options=DEFAULT_OPTIONS )
			options = DEFAULT_OPTIONS.merge( options || {} )

			options.each do |name, value|
				self.public_send( "#{name}=", value )
			end

			@resolver = Resolv::DNS.new
		end


		######
		public
		######

		# The timeout for connecting, in seconds.
		attr_accessor :timeout

		##
		# The stub resolver used for lookups
		attr_reader :resolver


		### Run the domain check for each of the specified Hash of +nodes+ and return a Hash of
		### updates for them based on their DNS domain record's status.
		def run( nodes )
			self.log.debug "Got %d nodes to check with %p" % [ nodes.length, self ]
			lookups = self.create_lookups( nodes )
			return self.wait_for_responses( lookups, nodes )
		end


		### Create lookups for all the names in the specified +nodes+ and return a Hash
		### of node identifiers keyed by the lookup Thread that is fetching the record.
		def create_lookups( nodes )
			return nodes.each_with_object( {} ) do |(identifier, node), hash|
				self.log.debug "Creating lookup for node: %p" % [ node ]
				name = node['name'] or next
				record_type = node['record_type'] || 'A'
				record_class = Resolv::DNS::Resource::IN.const_get( record_type ) or
					raise "Unsupported record type %p!" % [ record_type ]

				self.log.debug "Looking up %s record for %s (%s)" % [ record_type, name, identifier ]
				thr = Thread.new do
					self.resolver.getresources( name, record_class )
				end
				hash[ thr ] = identifier
			end
		end


		### Wait for the lookup threads in +lookups+ to finish and return a Hash of node
		### updates.
		def wait_for_responses( lookups, nodes )
			update = {}

			until lookups.empty?

				lookups.keys.each do |thr|
					next if thr.alive?

					identifier = lookups.delete( thr )
					begin
						records = thr.value

						if !records
							update[ identifier ] = { error: "Lookup failed (timeout)." }
						elsif records.empty?
							update[ identifier ] = { error: "Lookup failed (no records returned)." }
						else
							node_data = nodes[ identifier ]
							update[ identifier ] = self.compare_values( records, node_data )
						end
					rescue SystemCallError => err
						msg = "%p: %s" % [ err.class, err.message ]
						self.log.error "%s while looking up %s" % [ msg, identifier ]
						update[ identifier ] = { error: msg }
					end
				end

			end

			return update
		end


		### Compare the given resolver +records+ with the +node_data+, and
		### create an update hash describing the results.
		def compare_values( records, node_data )
			type = node_data['record_type']

			case type
			when 'A'
				return self.compare_a_records( records, node_data['values'] )
			when 'NS'
				return self.compare_ns_records( records, node_data['values'] )
			when 'MX'
				return self.compare_mx_records( records, node_data['values'] )
			else
				return { dns: "#{type} not comparable yet." }
			end
		end


		### Compare the addresses in the specified +records+ with the given +addresses+ and
		### error if any are not present.
		def compare_a_records( records, addresses )
			record_addresses = Set.new( records.map(&:address) )
			addresses = Set.new( addresses.map {|addr| Resolv::IPv4.create(addr)} )

			status = nil
			if addresses.subset?( record_addresses )
				status = { a_record: {addresses: record_addresses.map(&:to_s)} }
			else
				missing = addresses - record_addresses
				status = { error: "missing A records: %s" % [ missing.map(&:to_s).join(', ') ] }
			end

			return status
		end


		### Compare the expected +hosts+ with those in the fetched NS +records+.
		def compare_ns_records( records, hosts )
			record_hosts = Set.new( records.map(&:name) )
			hosts = Set.new( hosts.map {|name| Resolv::DNS::Name.create(name + '.')} )

			self.log.debug "Comparing %p to %p" % [ record_hosts, hosts ]

			status = nil
			if ( record_hosts ^ hosts ).empty?
				status = { ns_record: record_hosts.map(&:to_s) }
			elsif !( subset = record_hosts - hosts ).empty?
				status = { error: "missing NS records: %s" % [subset.map(&:to_s).join(', ')] }
			elsif !( subset = hosts - record_hosts ).empty?
				status = { error: "extra NS records: %s" % [subset.map(&:to_s).join(', ')] }
			end

			return status
		end


		### Compare the expected +hosts+ with those in the fetched MX +records+.
		def compare_mx_records( records, hosts )
			record_hosts = Set.new( records.map(&:exchange) )
			hosts = Set.new( hosts.map {|name| Resolv::DNS::Name.create(name + '.')} )

			self.log.debug "Comparing %p to %p" % [ record_hosts, hosts ]

			status = nil
			if ( record_hosts ^ hosts ).empty?
				record_strings = records.
					map {|rec| "%s[%d]" % [rec.exchange, rec.preference || 0] }
				status = {
					mx_record: record_strings.join( ', ' )
				}
			elsif !( subset = record_hosts - hosts ).empty?
				status = { error: "missing MX records: %s" % [subset.map(&:to_s).join(', ')] }
			elsif !( subset = hosts - record_hosts ).empty?
				status = { error: "extra MX records: %s" % [subset.map(&:to_s).join(', ')] }
			end

			return status
		end

	end # class Records

end # module Arborist::Monitor::DNS

