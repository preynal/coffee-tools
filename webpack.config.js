"use strict";

var webpack = require("webpack");

module.exports = {
    entry: "./index.coffee",
    resolve: {
        extensions: ["", ".coffee", ".js"]
    },
    target: "node",
    output: {
        path: __dirname,
        filename: "index.js",
        library: true,
        libraryTarget: "commonjs2"
    },
    plugins: [
        new webpack.optimize.DedupePlugin(),
        new webpack.optimize.UglifyJsPlugin()
    ],
    module: {
        loaders: [
            {test: /\.coffee$/, loader: "coffee"},
            {test: /\.json$/, loader: "json"}
        ]
    },
};
