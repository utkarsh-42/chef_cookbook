name 'docker_metrics'
default_source :supermarket
run_list 'docker_metrics::default'
cookbook 'docker_metrics', path: '.'
cookbook 'docker', '~> 9.0'
