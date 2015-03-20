# Usage:
#  - Describe zabbix hosts (short format)
#    $ bundle exec ruby describe_zabbix_hosts.rb 
#  - Describe zabbix hosts (long format)
#    $ bundle exec ruby describe_zabbix_hosts.rb -v 
#  - Describe a specific zabbix host (long format)
#    $ bundle exec ruby describe_zabbix_hosts.rb -h web-001

require 'bundler/setup'
require 'zabbixapi'
require 'yaml'
require 'optparse'
require 'pp'

yamlfile = "./zabbix.yaml"
zbxcnf = YAML.load(open(yamlfile).read)['zabbix']

ZABBIX_SERVER = zbxcnf['server']
ZABBIX_USERNAME = zbxcnf['username']
ZABBIX_PASSWORD = zbxcnf['password']
ZABBIX_API_URL = "https://#{ZABBIX_SERVER}/api_jsonrpc.php"

options = {
  :verbose => false
}

OptionParser.new do |opt|
  opt.on("-h hostname", "hostname") do |host|
    options[:hostname] = host
  end

  opt.on("-v", "verbose") do |host|
    options[:verbose] = true
  end

  opt.parse!(ARGV)
end

out = Hash.new()
outs = Array.new()
zbx = ZabbixApi.connect(:url => ZABBIX_API_URL, :user => ZABBIX_USERNAME, :password => ZABBIX_PASSWORD)

if (options[:hostname]) then
  out = zbx.hosts.get_full_data({:host => options[:hostname]})[0]
  out.merge!(zbx.query(:method => "hostinterface.get", :params => {"output" => "extend", "hostids" => out["hostid"]})[0])
  pp out
  exit
end 

if (options[:verbose] == false) then
  zbx.hosts.all.sort.each do |h| 
    hostname, hostid = h[0], h[1]
    hostip = zbx.query(:method => "hostinterface.get", :params => {"output" => "extend", "hostids" => hostid})[0]["ip"]
    out.store(hostname, hostip)
  end
  outs.push(out)
else
  zbx.hosts.get("output" => "extend").each do |h| 
    out = h
    out.merge!(zbx.query(:method => "hostinterface.get", :params => {"output" => "extend", "hostids" => out["hostid"]})[0])
    outs.push(out)
  end
  outs.sort_by!{|val|val['host']}
end

if (options[:verbose] == false) then
  outs.each do |h|
    h.each do |k, v|
      print k, " ", v, "\n"
    end
  end
else
  pp outs
end

