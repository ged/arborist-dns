# -*- ruby -*-
#encoding: utf-8

require 'arborist/dns'
require 'arborist/node/resource'
require 'arborist/mixins'


# A DNS domain resource node type for Arborist
class Arborist::Node::DNSDomain < Arborist::Node::Resource
	extend Loggability,
	       Arborist::MethodUtilities


	# Loggability API -- use the logger for this library
	log_to :arborist_dns

	# DNS names live under Host nodes
	parent_type :host


	### Create a new DNSDomain node with the given +domain_name+.
	def initialize( domain_name, host, attributes={}, &block )
		raise Arborist::NodeError, "no host given" unless host.is_a?( Arborist::Node::Host )

		identifier = "%s-domain" % [ domain_name.gsub(/\W+/, '-') ]
		attributes[ :name ] = domain_name
		attributes[ :category ] = 'dnsdomain'

		super( identifier, host, attributes, &block )
	end


	######
	public
	######

	##
	# Get/set the domain name in question
	dsl_accessor :name


	### Set service +attributes+.
	def modify( attributes )
		attributes = stringify_keys( attributes )
		super
		self.name( attributes['name'] )
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
		return super.merge( name: self.name )
	end


	### Serialize the resource node.  Return a Hash of the host node's state.
	def to_h( * )
		return super.merge( name: self.name )
	end


	### Returns +true+ if the node matches the specified +key+ and +val+ criteria.
	def match_criteria?( key, val )
		self.log.debug "Matching %p: %p against %p" % [ key, val, self ]
		return case key
			when 'name'
				self.name.downcase == val.downcase
			else
				super
			end
	end

end # class Arborist::Node::DNSDomain
