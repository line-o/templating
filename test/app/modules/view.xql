xquery version "3.1";

import module namespace templates="http://exist-db.org/xquery/html-templating";
import module namespace lib="http://exist-db.org/xquery/html-templating/lib";


import module namespace test="test" at "test.xqm";

declare namespace app="app";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "html5";
declare option output:media-type "text/html";

(:~
 : A wrapping template function that just returns a map will
 : - extend the model and
 : - process all child nodes
 :)
declare
    %templates:wrap
function app:init-data($node as node(), $model as map(*)) {
    map {
        "addresses": (
            map {
                "name": "Berta Muh",
                "street": "An der Viehtränke 13",
                "city": "Kuhweide"
            },
            map {
                "name": "Rudi Rüssel",
                "street": "Am Zoo 45",
                "city": "Tierheim"
            }
        ),
        "data": map {
            "test": "TEST1",
            "nested": map {
                "test": "TEST2"
            }
        }
    }
};

declare variable $app:lookup :=
    function ($name as xs:string, $arity as xs:integer) as function(*)? {
        function-lookup(xs:QName($name), $arity)
    };


(:
 : The HTML is passed in the request from the controller.
 : Run it through the templating system and return the result.
 :)
templates:apply(
    request:get-data(),
    $app:lookup,
    map { "my-model-item": 'xxx' },
    map {
        $templates:CONFIG_APP_ROOT      : $test:app-root,
        $templates:CONFIG_STOP_ON_ERROR : true()
    })

(: alternative :)
(:
templates:render(
    request:get-data(),
    map { "my-model-item": 'xxx' },
    map {
        $templates:CONFIG_QNAME_RESOLVER : xs:QName(?),
        $templates:CONFIG_APP_ROOT       : $test:app-root,
        $templates:CONFIG_STOP_ON_ERROR  : true()
    })
:)
