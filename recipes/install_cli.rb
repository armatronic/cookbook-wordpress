# Wordpress CLI installation
# https://github.com/wp-cli/wp-cli
include_recipe "wordpress"
include_recipe "git"
# WP-CLI requires Composer now.
include_recipe "composer"

# Set up Wordpress CLI.
# Use wordpress settings as a base unless overwritten.
config  = node[:wordpress]
command = "#{config[:cli_install_dir]}/bin/wp"
git config[:cli_install_dir] do
  repository        "git://github.com/wp-cli/wp-cli.git"
  reference         "master"
  action            :sync
  enable_submodules true
end

# Set up Composer dependencies that WP-CLI uses.
execute "composer install" do
  cwd    config[:cli_install_dir]
  action :run
end

# Which URL should this be installed to?
install_url = config[:url]
unless install_url
  if node.has_key?("ec2")
    install_url = node['ec2']['public_hostname']
  else
    install_url = node['fqdn']
  end
end


execute "#{command} core is-installed" do
  action :nothing
  # ignore_failure true
  returns [0,1]
end
# Which directory should it be installed to?
#log(node.ipaddress)
#log(node.inet_address)
# Use URL if it's supplied, otherwise use FQDN?
# If using FQDN, need to ensure that host recognises it.
execute "#{command} core install \
  --url=\"#{install_url}\" \
  --title=\"#{config[:site_title]}\" \
  --admin_email=\"#{config[:admin][:email]}\" \
  --admin_name=\"#{config[:admin][:user]}\" \
  --admin_password=\"#{config[:admin][:password]}\"" do
  cwd    config[:dir]
  action :run
  # 1 means that the blog is already installed, so ignore that.
  returns [0,1]
  # This command returns 0 if installed, 1 if not.
  #only_if "#{command} core is-installed"
end


# Run each CLI command.
config[:cli_commands].each do |cli_command|
  execute "#{command} #{cli_command}" do
    cwd    config[:dir]
    action :run
  end
end
