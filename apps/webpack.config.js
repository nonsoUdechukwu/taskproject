var path = require('path');

module.exports = (env, argv) => {
    const isProduction = argv.mode === 'production';

    return {
        entry: './src/main/js/app.js',
        devtool: isProduction ? 'source-map' : 'inline-source-map',
        cache: true,
        mode: isProduction ? 'production' : 'development',
        resolve: {
            alias: {
                'stompjs': path.resolve(__dirname, 'node_modules', 'stompjs/lib/stomp.js'),
            }
        },
        output: {
            path: path.resolve(__dirname, 'build'),  // This should match the Dockerfile COPY command
            filename: 'bundle.js'
        },
        module: {
            rules: [
                {
                    test: /\.js$/,
                    exclude: /node_modules/,
                    use: {
                        loader: 'babel-loader',
                        options: {
                            presets: ['@babel/preset-env', '@babel/preset-react']
                        }
                    }
                }
            ]
        },
        devServer: {
            contentBase: path.join(__dirname, 'public'),
            compress: true,
            port: 9000
        }
    };
};
