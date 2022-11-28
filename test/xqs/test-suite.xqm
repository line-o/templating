xquery version "3.1";

(:~
 : XQSuite tests for the templating library.
 :
 : @author eXist-db Project
 : @see http://exist-db.org
 :)

module namespace tt = "http://exist-db.org/templating/tests";

import module namespace templates="http://exist-db.org/xquery/html-templating";


declare namespace test="http://exist-db.org/xquery/xqsuite";

(:~
 : template with
 : - calls to functions annotated wit %templates:wrap
 : - nested template function calls
 : - and templates:each
 :)
declare variable $tt:template :=
    <html>
        <body data-template="tt:tf" class="body" data-extra="7">
            <ul>
                <li data-template="templates:each" data-template-from="data" data-template-to="item"
                    data-extra="23" class="item">
                    <span data-template="tt:n" data-extra="42" class="value"></span>
                </li>
            </ul>
        </body>
    </html>
;

declare variable $tt:data := 
    <data>
        <a n="1" />
        <a n="3" />
        <b n="2" />
        <c n="str" />
    </data>
;

declare variable $tt:lookup := function ($name, $arity) {
    function-lookup(xs:QName($name), $arity)
};
declare variable $tt:qname-resolve := xs:QName(?);

(:~
 : minimum configuration to allow testing in XQSuite
 : as request:* is not bound to anything in this context
 :)
declare variable $tt:config-xqsuite-default := map {
    $templates:CONFIG_PARAM_RESOLVER : tt:resolver#1
};

(: templating configuration :)
declare variable $tt:config-filter := map {
    $templates:CONFIG_PARAM_RESOLVER : tt:resolver#1,
    $templates:CONFIG_FILTER_ATTRIBUTES : true()
};

(: templating configuration :)
declare variable $tt:config-no-filter := map {
    $templates:CONFIG_PARAM_RESOLVER : tt:resolver#1,
    $templates:CONFIG_FILTER_ATTRIBUTES : false()
};

declare variable $tt:config-render := map {
    $templates:CONFIG_FN_RESOLVER : $tt:lookup,
    $templates:CONFIG_PARAM_RESOLVER : tt:resolver#1,
    $templates:CONFIG_FILTER_ATTRIBUTES : false()
};

(: parameters cannot be resolved with default resolver in XQSuite context :)
declare function tt:resolver ($m) { () };


(: helper function to test for the existence of data-attributes 
 : used in templating
 :)
declare
    %private
function tt:get-template-attribute-values ($xml as node()) {
    $xml//@*[starts-with(local-name(.), $templates:ATTR_DATA_TEMPLATE)]/string()
};

declare
    %private
function tt:get-extra-data-attribute-values ($xml as node()) {
    $xml//@data-extra/string()
};

declare
    %private
function tt:get-class-attribute-values ($xml as node()) {
    $xml//@class/string()
};

(:
 : ---------------------------
 : TEMPLATING
 : --------------------------- 
 :
 : templating functions for testing
 : Since functions annotated with %templates:replace do control the output
 : they are also in charge with to filter it. This is usually not necessary
 : as the output does not contain any data-templates-* attributes. 
 :)

declare
    %templates:wrap
function tt:tf ($node as node(), $model as map(*)) {
    count($model("data")),
    templates:process($node/node(), $model)
};

declare
    %templates:wrap
function tt:n ($node as node(), $model as map(*)) {
    $model("item")/@n/string()
};

(: ---------------------------
 : TESTS
 : --------------------------- :)

declare
    %test:assertEmpty
function tt:attributes-filtered-c() {
    templates:apply(
        $tt:template, $tt:lookup,
        map { 'data': $tt:data//c }, 
        $tt:config-filter
    )
    => tt:get-template-attribute-values()
};

declare
    %test:assertEmpty
function tt:attributes-filtered-a() {
    templates:apply(
        $tt:template, $tt:lookup,
        map { 'data': $tt:data//a }, 
        $tt:config-filter
    )
    => tt:get-template-attribute-values()
};

declare
    %test:assertEquals("7", "23", "42", "23", "42")
function tt:attributes-filtered-a-extra() {
    templates:apply(
        $tt:template, $tt:lookup,
        map { 'data': $tt:data//a }, 
        $tt:config-filter
    )
    => tt:get-extra-data-attribute-values()
};

declare
    %test:assertEquals("body", "item", "value", "item", "value")
function tt:attributes-filtered-a-class() {
    templates:apply(
        $tt:template, $tt:lookup,
        map { 'data': $tt:data//a }, 
        $tt:config-filter
    )
    => tt:get-class-attribute-values()
};

declare
    %test:assertEquals("tt:tf", "templates:each", "data", "item", "tt:n")
function tt:attributes-unfiltered-c() {
    templates:apply(
        $tt:template, $tt:lookup,
        map { 'data': $tt:data//c }, 
        $tt:config-no-filter
    )
    => tt:get-template-attribute-values()
};

declare
    %test:assertEquals("tt:tf", "templates:each", "data", "item", "tt:n", "templates:each", "data", "item", "tt:n")
function tt:attributes-unfiltered-a() {
    templates:apply(
        $tt:template, $tt:lookup,
        map { 'data': $tt:data//a },
        $tt:config-no-filter
    )
    => tt:get-template-attribute-values()
};

declare
    %test:assertEquals("tt:tf", "templates:each", "data", "item", "tt:n", "templates:each", "data", "item", "tt:n")
function tt:attributes-unfiltered-by-default() {
    templates:apply(
        $tt:template, $tt:lookup,
        map { 'data': $tt:data//a },
        $tt:config-xqsuite-default
    )
    => tt:get-template-attribute-values()
};

declare
    %test:assertEquals("tt:tf", "templates:each", "data", "item", "tt:n", "templates:each", "data", "item", "tt:n")
function tt:render-qname-resolver() {
    templates:render(
        $tt:template,
        map { 'data': $tt:data//a },
        map {
            $templates:CONFIG_QNAME_RESOLVER : $tt:qname-resolve,
            $templates:CONFIG_PARAM_RESOLVER : tt:resolver#1,
            $templates:CONFIG_FILTER_ATTRIBUTES : false()
        }
    )
    => tt:get-template-attribute-values()
};

declare
    %test:assertEquals("tt:tf", "templates:each", "data", "item", "tt:n", "templates:each", "data", "item", "tt:n")
function tt:render-fn-resolver() {
    templates:render(
        $tt:template,
        map { 'data': $tt:data//a },
        map {
            $templates:CONFIG_FN_RESOLVER : $tt:lookup,
            $templates:CONFIG_PARAM_RESOLVER : tt:resolver#1,
            $templates:CONFIG_FILTER_ATTRIBUTES : false()
        }
    )
    => tt:get-template-attribute-values()
};

declare
    %test:assertError("err:XPST0081")
function tt:render-no-lookup() {
    templates:render(
        $tt:template,
        map { 'data': $tt:data//a },
        map {
            $templates:CONFIG_PARAM_RESOLVER : tt:resolver#1,
            $templates:CONFIG_FILTER_ATTRIBUTES : true()
        }
    )
    => tt:get-template-attribute-values()
};

declare
    %test:assertEquals(2)
function tt:render-no-lookup-success() {
    templates:render(
        <html><body><p data-template="templates:each" data-template-from="data" data-template-to="item">item</p></body></html>,
        map { 'data': $tt:data//a },
        map {
            $templates:CONFIG_PARAM_RESOLVER : tt:resolver#1,
            $templates:CONFIG_FILTER_ATTRIBUTES : true()
        }
    )//p => count()
};

declare
    %test:assertError("templates:NotFound")
function tt:render-max-arity-2() {
    templates:render(
        <html><body><p data-template="templates:each" data-template-from="data" data-template-to="item">item</p></body></html>,
        map { 'data': $tt:data//a },
        map {
            $templates:CONFIG_PARAM_RESOLVER : tt:resolver#1,
            $templates:CONFIG_MAX_ARITY : 2,
            $templates:CONFIG_STOP_ON_ERROR : true()
        }
    )//p => count()
};

declare
    %test:assertEquals(2)
function tt:render-max-arity-4() {
    templates:render(
        <html><body>
            <p data-template="templates:each" data-template-from="data" data-template-to="item">item</p>
        </body></html>,
        map { 'data': $tt:data//a },
        map {
            $templates:CONFIG_PARAM_RESOLVER : tt:resolver#1,
            $templates:CONFIG_MAX_ARITY : 4,
            $templates:CONFIG_STOP_ON_ERROR : true()
        }
    )//p => count()
};

declare
    %test:assertEquals("1","3","2","str")
function tt:render-with-parse-params-custom-delimiter() {
    templates:render(
        <html><body>
            <p data-template="templates:each" data-template-from="data" data-template-to="item">
                <span data-template="templates:parse-params">[[item]]</span>
            </p>
        </body></html>,
        map { 'data': $tt:data//@n },
        map {
            $templates:CONFIG_PARAM_RESOLVER : tt:resolver#1,
            $templates:START_DELIMITER: '\[\[',
            $templates:END_DELIMITER: '\]\]'
        }
    )
    //p/span/text()
};
