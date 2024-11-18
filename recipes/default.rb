# Install required packages first
%w(apt-transport-https ca-certificates curl software-properties-common gnupg).each do |pkg|
  package pkg do
    action :install
  end
end

# Add Docker repository
execute 'add-docker-key' do
  command 'curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -'
  action :run
  not_if 'apt-key list | grep Docker'
end

execute 'add-docker-repo' do
  command 'add-apt-repository "deb [arch=arm64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"'
  action :run
  not_if 'grep docker /etc/apt/sources.list.d/*'
end

# Install Docker
execute 'apt-update' do
  command 'apt-get update'
  action :run
end

%w(docker-ce docker-ce-cli containerd.io).each do |pkg|
  package pkg do
    action :install
  end
end

# Start Docker daemon directly
execute 'start-docker-daemon' do
  command 'dockerd > /var/log/dockerd.log 2>&1 &'
  not_if 'pgrep dockerd'
  action :run
end

# Wait for Docker daemon
ruby_block 'wait-for-docker' do
  block do
    Chef::Log.info('Waiting for Docker daemon to be ready...')
    30.times do
      if system('docker ps > /dev/null 2>&1')
        Chef::Log.info('Docker daemon is ready')
        break
      end
      Chef::Log.info('Docker not ready, waiting...')
      sleep 2
    end
    raise 'Docker failed to start after 60 seconds' unless system('docker ps > /dev/null 2>&1')
  end
  action :run
end

# Create directory for metrics app
directory '/opt/metrics_app' do
  owner 'root'
  group 'root'
  mode '0755'
  recursive true
  action :create
end

# Copy metrics app files
%w(app.js package.json Dockerfile).each do |file|
  cookbook_file "/opt/metrics_app/#{file}" do
    source "metrics_app/#{file}"
    owner 'root'
    group 'root'
    mode '0644'
  end
end

# Create Docker network
execute 'create-docker-network' do
  command 'docker network create metrics_network || true'
  action :run
end

# Pull and run main container
execute 'pull-main-container' do
  command 'docker pull utkarsh42/docker-challenge-solved-utkarsh-agrawal:latest'
  action :run
end

execute 'run-main-container' do
  command 'docker rm -f main-app || true; docker run -d --name main-app --network metrics_network -p 8080:80 utkarsh42/docker-challenge-solved-utkarsh-agrawal:latest'
  action :run
end

# Build and run metrics container
execute 'build-metrics-container' do
  command 'cd /opt/metrics_app && docker build -t metrics-app:latest .'
  action :run
end

execute 'run-metrics-container' do
  command 'docker rm -f metrics-app || true; docker run -d --name metrics-app --network metrics_network -p 9100:9100 metrics-app:latest'
  action :run
end

# Verify deployment
ruby_block 'verify-deployment' do
  block do
    # Check Docker daemon
    raise 'Docker daemon not running' unless system('pgrep dockerd > /dev/null')
    
    # Check containers
    raise 'Main container not running' unless system('docker ps | grep main-app > /dev/null')
    raise 'Metrics container not running' unless system('docker ps | grep metrics-app > /dev/null')
    
    Chef::Log.info('Deployment verification completed successfully')
  end
  action :run
end
