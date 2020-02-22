#!/usr/bin/env rspec -cfd

require_relative '../../spec_helper'

require 'arborist/mixins'
require 'arborist/dns'


describe Arborist::Monitor::DNS do

	using Arborist::TimeRefinements


	describe Arborist::Monitor::DNS::Domain do

		let( :monitor ) { described_class.new }
		let( :host_node ) do
			Arborist::Node.create( :host, 'webserver' ) do
				description "Test host node with a few web services"
				address '10.2.18.64'
				tags :testing
			end
		end

		let( :dnsdomain_node1 ) { host_node.dnsdomain('chumpy.store') }
		let( :dnsdomain_node2 ) { host_node.dnsdomain('example.com') }
		let( :dnsdomain_node3 ) { host_node.dnsdomain('tribaltats.club') }

		let( :nodes ) {[ dnsdomain_node1, dnsdomain_node2, dnsdomain_node3 ]}
		let( :nodes_hash ) do
			nodes.each_with_object({}) do |node, accum|
				accum[ node.identifier ] = node.fetch_values
			end
		end


		it "is created with a default timeout" do
			expect( monitor.timeout ).to be_an( Integer )
		end


		it "can clone itself with a new timeout" do
			new_monitor = monitor.with_timeout( 2.minutes )
			expect( new_monitor ).to_not equal( monitor )
			expect( new_monitor.timeout ).to eq( 2.minutes )
		end


		it "runs against a collection of nodes and updates the statuses of each one" do
			monitor.client = instance_double( Whois::Client )

			rec1 = instance_double( Whois::Record )

			expect( monitor.client ).to receive( :lookup ).with( dnsdomain_node1.name ).
				and_return( rec1 )

			result = monitor.run( nodes_hash )

			expect( result ).to be_a( Hash )
			expect( result.keys ).to contain_exactly( *nodes.map(&:identifier) )
		end


		it "sets an error for error response statuses"

	end



end

