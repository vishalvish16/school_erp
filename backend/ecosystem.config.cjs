module.exports = {
    apps: [
        {
            name: 'school-erp-backend',
            script: 'src/server.js',
            instances: 'max',
            exec_mode: 'cluster',
            autorestart: true,
            watch: true,
            ignore_watch: ['node_modules', 'logs'],
            max_memory_restart: '1G',
            env: {
                NODE_ENV: 'development',
            },
            env_production: {
                NODE_ENV: 'production',
            },
            error_file: 'logs/pm2-error.log',
            out_file: 'logs/pm2-out.log',
            log_date_format: 'YYYY-MM-DD HH:mm:ss',
            merge_logs: true,
        },
    ],
};
