# Chef InSpec test for recipe docker_metrics::default

# The Chef InSpec reference, with examples and extensive documentation, can be
# found at https://docs.chef.io/inspec/resources/

describe port(8080) do
  it { should be_listening }
end

describe port(9100) do
  it { should be_listening }
end

describe docker_container('main-app') do
  it { should exist }
  it { should be_running }
end

describe docker_container('metrics-app') do
  it { should exist }
  it { should be_running }
end

describe http('http://localhost:9100/metrics') do
  its('status') { should eq 200 }
  its('body') { should include 'system_cpu_usage' }
  its('body') { should include 'system_memory_usage' }
  its('body') { should include 'system_disk_usage' }
end
