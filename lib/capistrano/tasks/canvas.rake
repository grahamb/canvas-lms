namespace :deploy do
  desc 'Restart application'
  task :restart do
    on roles(:all) do
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end
end

namespace :canvas do

  desc "Set application nodes from config file"
  task :set_app_nodes do
    on primary :db do
      stage = fetch :stage
      prefix = fetch :app_node_prefix
      nodes = capture "/usr/local/canvas/bin/getappnodes #{stage}"
      range = *(1..nodes.to_i)
      roles[:app].clear
      range.each do |node|
        parent.role :app, "#{prefix}#{node}.tier2.sfu.ca"
      end
    end
  end

  desc "Run the copy_config script"
  task :copy_config do
    puts "original"
    on roles(:all) do
      execute "sudo CANVASDIR=#{release_path} /etc/init.d/canvasconfig start"
    end
  end

  desc "Log the deploy to graphite"
  task :log_deploy do
    ts = Time.now.to_i
    cmd = "echo 'stats.canvas.#{stage}.deploys 1 #{ts}' | nc #{stats_server} 2003"
    run_locally do
      execute cmd
    end
  end

  desc "Ping the canvas server to actually restart the app"
  task :ping do
    run_locally do
      execute "curl -m 10 --silent #{fetch(:canvas_url)}/sfu/api/v1/terms/current"
    end
  end

  desc "Create symlink for files folder to mount point"
  task :symlink_canvasfiles do
    on roles(:all) do
      execute "mkdir -p #{release_path}/mnt/data && ln -s /mnt/data/canvasfiles #{release_path}/mnt/data/canvasfiles"
    end
  end

end