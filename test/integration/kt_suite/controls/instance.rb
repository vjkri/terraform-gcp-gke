title 'Check GKE Cluster'

PROJECT_NAME = attribute('gcp_project_id', description: 'gcp project name')
CLUSTER_NAME = attribute('cluster_name', description: 'gcp cluster name')
CLUSTER_ZONE = attribute('gcp_location', description: 'gcp cluster zone')

control 'instance' do
  title 'Check GKE Cluster'

  describe google_container_cluster(project: PROJECT_NAME, zone: CLUSTER_ZONE, name: CLUSTER_NAME) do
    it { should exist }
    its('name') { should eq CLUSTER_NAME }
    its('status') { should eq 'RUNNING' }
    its('zone') { should match CLUSTER_ZONE }
    its('network') { should eq 'vpc-network' }
    its('subnetwork') { should eq 'vpc-subnetwork' }
    its('initial_node_count') { should eq 1 }
    its('node_config.disk_size_gb'){should eq 100}
    its('node_config.image_type'){should eq "COS"}
    its('node_pools.count'){should eq 2}
    its('private_cluster_config.enable_private_nodes'){should eq true}
  end

  google_container_node_pools(project: PROJECT_NAME, zone: CLUSTER_ZONE, cluster_name: CLUSTER_NAME).node_pool_names.each do |node_pool_name_standard|
    describe google_container_node_pool(project: PROJECT_NAME, zone: CLUSTER_ZONE, cluster_name: CLUSTER_NAME, nodepool_name: node_pool_name_standard) do
      it { should exist }
      its('status') { should eq 'RUNNING' }
    end
  end

  google_container_node_pools(project: PROJECT_NAME, zone: CLUSTER_ZONE, cluster_name: CLUSTER_NAME).node_pool_names.each do |node_pool_name_highmem|
    describe google_container_node_pool(project: PROJECT_NAME, zone: CLUSTER_ZONE, cluster_name: CLUSTER_NAME, nodepool_name: node_pool_name_highmem) do
      it { should exist }
      its('status') { should eq 'RUNNING' }
    end
  end

  google_compute_networks(project: PROJECT_NAME).network_names.each do |network_name|
    describe google_compute_network(project: PROJECT_NAME,  name: network_name) do
      its ('subnetworks.count') { should be < 30 }
      its ('creation_timestamp_date') { should be > Time.now - 365*60*60*24*10 }
      its ('routing_config.routing_mode') { should eq "REGIONAL" }
    end
  end

end