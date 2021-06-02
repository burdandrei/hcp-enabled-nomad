#!/bin/bash
# This script is meant to be run in the User Data of each EC2 Instance while it's booting.
set -e
set -x

export TERM=xterm-256color
export DEBIAN_FRONTEND=noninteractive

# Send the log output from this script to user-data.log, syslog, and the console
# From: https://alestic.com/2010/12/ec2-user-data-output/
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

apt-get update
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common \
    jq \
    unzip

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io


#####
# Configure resolving
#####

echo "Determining local IP address"
LOCAL_IPV4=$(hostname --ip-address)


mkdir -p /etc/systemd/resolved.conf.d
cat << EOSDRCF >/etc/systemd/resolved.conf.d/consul.conf
# Enable forward lookup of the 'consul' domain:
[Resolve]
Cache=no
DNS=127.0.0.1:8600
Domains=~.consul
EOSDRCF

cat << EOSDRLF >/etc/systemd/resolved.conf.d/listen.conf
# Enable listener on private ip:
[Resolve]
DNSStubListenerExtra=${LOCAL_IPV4}
EOSDRLF

systemctl restart systemd-resolved.service

cat << EODDJ >/etc/docker/daemon.json
{
  "dns": ["${LOCAL_IPV4}"],
  "dns-search": ["service.consul"]
}
EODDJ

systemctl restart docker.service


######
# Install Consul and Nomad
######

echo "Checking latest Consul and Nomad versions..."
CHECKPOINT_URL="https://checkpoint-api.hashicorp.com/v1/check"
CONSUL_VERSION=$(curl -s "$${CHECKPOINT_URL}"/consul | jq -r .current_version)
NOMAD_VERSION=$(curl -s "$${CHECKPOINT_URL}"/nomad | jq -r .current_version)

cd /tmp/

echo "Fetching Consul version $${CONSUL_VERSION} ..."
curl -s https://releases.hashicorp.com/consul/$${CONSUL_VERSION}/consul_$${CONSUL_VERSION}_linux_amd64.zip -o consul.zip
echo "Installing Consul version $${CONSUL_VERSION} ..."
unzip consul.zip
chmod +x consul
mv consul /usr/local/bin/consul

echo "Fetching Nomad version $${NOMAD_VERSION} ..."
curl -s https://releases.hashicorp.com/nomad/$${NOMAD_VERSION}/nomad_$${NOMAD_VERSION}_linux_amd64.zip -o nomad.zip
echo "Installing Nomad version $${NOMAD_VERSION} ..."
unzip nomad.zip
chmod +x nomad
mv nomad /usr/local/bin/nomad

########
# Consul config
########

mkdir -p /etc/consul.d
mkdir -p /var/lib/consul
cat << EOCCF >/etc/consul.d/client.hcl
"acl" = {
  "default_policy" = "deny"

  "down_policy" = "async-cache"

  "enabled" = true
}

"auto_encrypt" = {
  "tls" = true
}

"ca_file" = "/var/lib/consul/ca.pem"

"datacenter" = "demo-consul"

"encrypt" = "LUg/+FizWDKpKgKGYMywyA=="

"encrypt_verify_incoming" = true

"encrypt_verify_outgoing" = true

"log_level" = "INFO"

"retry_join" = ["demo-consul.private.consul.6db67239-e33c-447f-be31-72943a3b3533.aws.hashicorp.cloud"]

"server" = false

"ui" = true

"verify_outgoing" = true

advertise_addr = "{{ GetPrivateIP }}"
client_addr =  "0.0.0.0"
data_dir = "/var/lib/consul"
EOCCF

cat << EOCACF >/etc/consul.d/acl.hcl
acl = {
    tokens = {
        agent = "${consul_acl_token}"
    }
}
EOCACF

cat << EOCCA >/var/lib/consul/ca.pem
${consul_ca_file}
EOCCA


cat << EOCSU >/etc/systemd/system/consul.service
[Unit]
Description="HashiCorp Consul - A service mesh solution"
Documentation=https://www.consul.io/
Requires=network-online.target
After=network-online.target

[Service]
Type=notify
ExecStart=/usr/local/bin/consul agent -config-dir=/etc/consul.d/
ExecReload=/bin/kill --signal HUP $MAINPID
KillMode=process
KillSignal=SIGTERM
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOCSU

##########
# Nomad config
##########

cat << EONEF >/etc/default/nomad
CONSUL_HTTP_TOKEN=${consul_acl_token}
EONEF

mkdir -p /etc/nomad.d/
cat << EONCF >/etc/nomad.d/client.hcl
bind_addr          = "0.0.0.0"
region             = "${nomad_region}"
datacenter         = "${nomad_datacenter}"
data_dir           = "/var/lib/nomad/"
log_level          = "DEBUG"
leave_on_interrupt = true
leave_on_terminate = true
client {
  enabled = true
}
EONCF

cat << EONVCF >/etc/nomad.d/vault.hcl
vault {
  enabled = true
  address = "${vault_endpoint}"
}
EONVCF

cat << EONSU >/etc/systemd/system/nomad.service
[Unit]
Description=nomad agent
Requires=network-online.target consul.service
After=network-online.target consul.service
[Service]
LimitNOFILE=65536
Restart=on-failure
EnvironmentFile=/etc/default/nomad
ExecStart=/usr/local/bin/nomad agent -config /etc/nomad.d
KillSignal=SIGINT
RestartSec=5s
[Install]
WantedBy=multi-user.target
EONSU

systemctl daemon-reload
systemctl start consul
systemctl start nomad
