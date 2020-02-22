#!/usr/bin/env rspec -cfd

require_relative '../../spec_helper'

require 'arborist/node/dnsrecord'


describe Arborist::Node::DNSRecord do

	it "lives under `host` nodes." do
		host_node = Arborist::Node.create( :host, 'www' )
		result = host_node.dnsrecord( 'www.example.com', record_type: :A, ip: '10.2.10.8' )

		expect( result ).to be_a( described_class )
		expect( result.name ).to eq( 'www.example.com' )
		expect( result.identifier ).to eq( 'www-www-example-com-dns-a-record' )
	end


	it "defaults to an `A` record"

end

