# -*- encoding: utf-8 -*-
# stub: arborist-dns 0.1.0.pre.20200221175259 ruby lib

Gem::Specification.new do |s|
  s.name = "arborist-dns".freeze
  s.version = "0.1.0.pre.20200221175259"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Michael Granger".freeze]
  s.date = "2020-02-21"
  s.description = "DNS Monitor and Node classes for Arborist. It can be used to monitor domain registration as well as individual DNS records.".freeze
  s.email = ["ged@faeriemud.org".freeze]
  s.files = ["History.md".freeze, "LICENSE.txt".freeze, "README.md".freeze, "lib/arborist/dns.rb".freeze, "lib/arborist/monitor/dns.rb".freeze, "lib/arborist/node/dnsdomain.rb".freeze, "lib/arborist/node/dnsrecord.rb".freeze]
  s.homepage = "http://hg.sr.ht/~ged/Arborist-DNS".freeze
  s.licenses = ["BSD-3-Clause".freeze]
  s.required_ruby_version = Gem::Requirement.new("~> 2.5".freeze)
  s.rubygems_version = "3.1.2".freeze
  s.summary = "DNS Monitor and Node classes for Arborist.".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<loggability>.freeze, ["~> 0.15"])
    s.add_runtime_dependency(%q<whois>.freeze, ["~> 4.0"])
    s.add_runtime_dependency(%q<whois-parser>.freeze, ["~> 1.0"])
    s.add_development_dependency(%q<rake-deveiate>.freeze, ["~> 0.10"])
    s.add_development_dependency(%q<simplecov>.freeze, ["~> 0.7"])
    s.add_development_dependency(%q<rdoc-generator-fivefish>.freeze, ["~> 0.3"])
  else
    s.add_dependency(%q<loggability>.freeze, ["~> 0.15"])
    s.add_dependency(%q<whois>.freeze, ["~> 4.0"])
    s.add_dependency(%q<whois-parser>.freeze, ["~> 1.0"])
    s.add_dependency(%q<rake-deveiate>.freeze, ["~> 0.10"])
    s.add_dependency(%q<simplecov>.freeze, ["~> 0.7"])
    s.add_dependency(%q<rdoc-generator-fivefish>.freeze, ["~> 0.3"])
  end
end
