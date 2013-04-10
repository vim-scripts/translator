/*jslint node: true, nomen: true, indent: 4, maxlen: 80, plusplus: true, sloppy: true, regexp: true */


(function () {
    'use strict';

    var resultHandlers = {
            'youdao': function (outputArr, resultObj) {
                //example
                //{
                //    "errorCode":0
                //    "query":"翻译",
                //    "translation":["translation"], // 有道翻译
                //    "basic":{ // 有道词典-基本词典
                //        "phonetic":"fān yì",
                //        "explains":[
                //            "translate",
                //            "interpret"
                //        ]
                //    },
                //    "web":[ // 有道词典-网络释义
                //        {
                //            "key":"翻译",
                //            "value":["translator",
                //              "translation",
                //              "translate",
                //              "Interpreter"]
                //        },
                //        {...}
                //    ]
                //}
                if (!resultObj) {
                    return;
                }
                if (resultObj.basic && resultObj.basic.explains &&
                        resultObj.basic.explains.length) {
                    outputArr.push(resultObj.basic.explains.join(';'));
                } else if (resultObj.translation &&
                        resultObj.translation.length) {
                    outputArr.push(resultObj.translation.join(';'));
                } else if (resultObj.web && resultObj.web.length) {
                    resultObj = resultObj.web[0];
                    if (resultObj.value && resultObj.value.length) {
                        outputArr.push(resultObj.value.join(';'));
                    }
                }
            },
            'baidu': function (outputArr, resultObj) {
                //reponse example
                //{
                //    "from":"en",
                //    "to":"zh",
                //    "trans_result":[{
                //          "src":"today",
                //          "dst":"\u4eca\u5929"
                //          }
                //      ]
                //}
                var result;
                if (!resultObj) {
                    return;
                }
                if (resultObj.trans_result && resultObj.trans_result.length) {
                    result = resultObj.trans_result[0];
                    if (result.dst) {
                        outputArr.push(result.dst);
                    }
                }

            },
            'google': function (outputArr, resultObj) {
                //
            }
        },
        ERROR_MSG = 'ERROR: Unable to get result from translation engine! ' +
                'Please try again.',
        /**
         * @param {String} host
         * @return {String} the engine name
         */
        getEngineByHost = function (host) {
            var key;
            host = String(host).toLowerCase();
            for (key in resultHandlers) {
                if (resultHandlers.hasOwnProperty(key) &&
                        host.indexOf(key) > -1) {
                    return key;
                }
            }
        },
        URL = require('url'),
        HTTP = require('http'),
        engine_url = process.argv[2],
        query = process.argv[3],
        user_agent = 'Mozilla/5.0 (X11; Linux i686; rv:7.0.1)' +
                ' Gecko/20100101 Firefox/7.0.1',
        translator = {};
    translator.translate = function (query) {
        var output = [],
            url,
            urlObj,
            encodeQuery = encodeURIComponent(query);
        url = engine_url.replace('<QUERY>', encodeQuery);
        urlObj = URL.parse(url);
        if (!urlObj || !urlObj.host || !urlObj.path) {
            return;
        }
        return HTTP.get({
            host: urlObj.host,
            path: urlObj.path,
            headers: {
                'user-agent': user_agent
            }
        }, function (res) {
            return res.on('data', function (chunk) {
                var jschunk,
                    engineName;
                try {
                    jschunk = eval('(' + chunk + ')');
                } catch (ex) {
                    //do nothing
                    jschunk = null;
                }
                if (!jschunk) {
                    return;
                }
                engineName = getEngineByHost(urlObj.host);
                if (!engineName) {
                    return;
                }
                resultHandlers[engineName](output, jschunk);
                //return console.log(output.join(';'));
            }).on('end', function () {
                var result = output.join(';');
                return console.log(result);
            });
        }).on('error', function () {
            return console.log(ERROR_MSG);
        });
    };

    translator.translate(query);

}).call(this);
