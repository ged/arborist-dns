# -*- ruby -*-
#encoding: utf-8

require 'arborist/dns'
require 'arborist/node/resource'
require 'arborist/mixins'


# A DNS name resource node type for Arborist
class Arborist::Node::DNSRecord < Arborist::Node::Resource
	extend Loggability,
	       Arborist::MethodUtilities


	# Loggability API -- use the logger for this library
	log_to :arborist_dns

	# DNS names live under Host nodes, and are in the form:
	#   dnsrecord <recordtype>, <name>, *<recorddata>
	parent_type :host do |record_type, name, *values|
		[ name, {record_type: record_type, values: values.flatten(1)} ]
	end


	### Create a new DNSRecord node with the given +hostname+.
	def initialize( name, host, attributes={}, &block )
		attributes[ :name ] = name
		attributes[ :record_type ] ||= :A
		attributes[ :category ] = "dns-%s-record" % [ attributes[:record_type].downcase ]

		identifier = "%s-%s" % [ name.gsub(/\P{Alnum}+/, '-'), attributes[:category] ]

		@values = []

		super( identifier, host, attributes, &block )
	end


	######
	public
	######

	##
	# Get/set the name associated with the record.
	dsl_accessor :name

	##
	# Get/set the type of record this node represents.
	dsl_accessor :record_type


	### Get/set the expected values for the record this node represents.
	def values( *values )
		if !values.empty?
			@values.replace( values.flatten )
		end
		return @values
	end


	### Set service +attributes+.
	def modify( attributes )
		attributes = stringify_keys( attributes )
		super
		self.name( attributes['name'] )
		self.record_type( attributes['record_type'] )
		self.values( attributes['values'] )
	end


	### Return node-specific information for #inspect.
	def node_description
		return " [%s]" % [
			self.name,
		]
	end


	### Return a Hash of the operational values that are included with the node's
	### monitor state.
	def operational_values
		return super.merge(
			name: self.name,
			record_type: self.record_type,
			values: self.values
		)
	end


	### Serialize the node. Return a Hash of the node's state.
	def to_h( * )
		return super.merge(
			name: self.name,
			record_type: self.record_type,
			values: self.values
		)
	end


	### Returns +true+ if the node matches the specified +key+ and +val+ criteria.
	def match_criteria?( key, val )
		self.log.debug "Matching %p: %p against %p" % [ key, val, self ]
		return case key
			when 'name'
				self.name.downcase == val.downcase
			when 'record_type'
				self.record_type.to_s.downcase == val.downcase
			when 'value', 'values'
				self.values.include?( val.downcase )
			else
				super
			end
	end

end # class Arborist::Node::DNSRecord
