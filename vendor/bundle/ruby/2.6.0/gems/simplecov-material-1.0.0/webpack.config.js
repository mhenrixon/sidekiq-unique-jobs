const path = require('path');
const autoprefixer = require('autoprefixer');

module.exports = {
  mode: 'development',
  entry: {
    application: ['./dist/app.scss', './dist/app.js'],
  },
  output: {
    filename: '[name].js',
    path: path.resolve(__dirname, 'public'),
    libraryTarget: 'window',
  },
  module: {
    rules: [
      {
        test: /\.scss$/,
        use: [
          {
            loader: 'file-loader',
            options: {
              name: 'application.css',
            },
          },
          {loader: 'extract-loader'},
          {loader: 'css-loader'},
          {loader: 'postcss-loader',
            options: {
              plugins: () => [autoprefixer()],
            },
          },
          {
            loader: 'sass-loader',
            options: {
              includePaths: ['./node_modules'],
            },
          },
        ],
      },
      {
        test: /\.(png|svg|jpg|gif)$/,
        use: [
          {
            loader: 'file-loader',
            options: {
              publicPath: 'images',
              outputPath: 'images',
            },
          },
        ],
      },
      {
        test: /\.(woff|woff2|eot|ttf|otf)$/,
        use: [
          {
            loader: 'file-loader',
            options: {
              publicPath: 'fonts',
              outputPath: 'fonts',
            },
          },
        ],
      },
      {
        test: /\.m?js$/,
        include: [
          path.resolve(__dirname, 'dist'),
        ],
        exclude: [
          path.resolve(__dirname, 'node_modules'),
        ],
        enforce: 'pre',
        enforce: 'post',
        loader: 'babel-loader',
        options: {
          presets: ['@babel/preset-env'],
        },
      },
    ],
  },
};
