# -*- ruby -*-
#encoding: utf-8

require 'arborist'


module Arborist::DNS
	extend Loggability

	# Loggability API -- set up a log host for this library
	log_as :arborist_dns


	# Package version
	VERSION = '0.0.1'

	# Version control revision
	REVISION = %q$Revision: d318b4f0d795 $


	### Return the name of the library with the version, and optionally the build ID if
	### +include_build+ is true.
	def self::version_string( include_build: false )
		str = "%p v%s" % [ self, VERSION ]
		str << ' (' << REVISION.strip << ')' if include_build
		return str
	end


	require 'arborist/monitor/dns'
	require 'arborist/node/dnsdomain'
	require 'arborist/node/dnsrecord'

end # module Arborist::DNS

