(function dartProgram(){function copyProperties(a,b){var s=Object.keys(a)
for(var r=0;r<s.length;r++){var q=s[r]
b[q]=a[q]}}function mixinPropertiesHard(a,b){var s=Object.keys(a)
for(var r=0;r<s.length;r++){var q=s[r]
if(!b.hasOwnProperty(q)){b[q]=a[q]}}}function mixinPropertiesEasy(a,b){Object.assign(b,a)}var z=function(){var s=function(){}
s.prototype={p:{}}
var r=new s()
if(!(Object.getPrototypeOf(r)&&Object.getPrototypeOf(r).p===s.prototype.p))return false
try{if(typeof navigator!="undefined"&&typeof navigator.userAgent=="string"&&navigator.userAgent.indexOf("Chrome/")>=0)return true
if(typeof version=="function"&&version.length==0){var q=version()
if(/^\d+\.\d+\.\d+\.\d+$/.test(q))return true}}catch(p){}return false}()
function inherit(a,b){a.prototype.constructor=a
a.prototype["$i"+a.name]=a
if(b!=null){if(z){Object.setPrototypeOf(a.prototype,b.prototype)
return}var s=Object.create(b.prototype)
copyProperties(a.prototype,s)
a.prototype=s}}function inheritMany(a,b){for(var s=0;s<b.length;s++){inherit(b[s],a)}}function mixinEasy(a,b){mixinPropertiesEasy(b.prototype,a.prototype)
a.prototype.constructor=a}function mixinHard(a,b){mixinPropertiesHard(b.prototype,a.prototype)
a.prototype.constructor=a}function lazy(a,b,c,d){var s=a
a[b]=s
a[c]=function(){if(a[b]===s){a[b]=d()}a[c]=function(){return this[b]}
return a[b]}}function lazyFinal(a,b,c,d){var s=a
a[b]=s
a[c]=function(){if(a[b]===s){var r=d()
if(a[b]!==s){A.wp(b)}a[b]=r}var q=a[b]
a[c]=function(){return q}
return q}}function makeConstList(a,b){if(b!=null)A.a(a,b)
a.$flags=7
return a}function convertToFastObject(a){function t(){}t.prototype=a
new t()
return a}function convertAllToFastObject(a){for(var s=0;s<a.length;++s){convertToFastObject(a[s])}}var y=0
function instanceTearOffGetter(a,b){var s=null
return a?function(c){if(s===null)s=A.pr(b)
return new s(c,this)}:function(){if(s===null)s=A.pr(b)
return new s(this,null)}}function staticTearOffGetter(a){var s=null
return function(){if(s===null)s=A.pr(a).prototype
return s}}var x=0
function tearOffParameters(a,b,c,d,e,f,g,h,i,j){if(typeof h=="number"){h+=x}return{co:a,iS:b,iI:c,rC:d,dV:e,cs:f,fs:g,fT:h,aI:i||0,nDA:j}}function installStaticTearOff(a,b,c,d,e,f,g,h){var s=tearOffParameters(a,true,false,c,d,e,f,g,h,false)
var r=staticTearOffGetter(s)
a[b]=r}function installInstanceTearOff(a,b,c,d,e,f,g,h,i,j){c=!!c
var s=tearOffParameters(a,false,c,d,e,f,g,h,i,!!j)
var r=instanceTearOffGetter(c,s)
a[b]=r}function setOrUpdateInterceptorsByTag(a){var s=v.interceptorsByTag
if(!s){v.interceptorsByTag=a
return}copyProperties(a,s)}function setOrUpdateLeafTags(a){var s=v.leafTags
if(!s){v.leafTags=a
return}copyProperties(a,s)}function updateTypes(a){var s=v.types
var r=s.length
s.push.apply(s,a)
return r}function updateHolder(a,b){copyProperties(b,a)
return a}var hunkHelpers=function(){var s=function(a,b,c,d,e){return function(f,g,h,i){return installInstanceTearOff(f,g,a,b,c,d,[h],i,e,false)}},r=function(a,b,c,d){return function(e,f,g,h){return installStaticTearOff(e,f,a,b,c,[g],h,d)}}
return{inherit:inherit,inheritMany:inheritMany,mixin:mixinEasy,mixinHard:mixinHard,installStaticTearOff:installStaticTearOff,installInstanceTearOff:installInstanceTearOff,_instance_0u:s(0,0,null,["$0"],0),_instance_1u:s(0,1,null,["$1"],0),_instance_2u:s(0,2,null,["$2"],0),_instance_0i:s(1,0,null,["$0"],0),_instance_1i:s(1,1,null,["$1"],0),_instance_2i:s(1,2,null,["$2"],0),_static_0:r(0,null,["$0"],0),_static_1:r(1,null,["$1"],0),_static_2:r(2,null,["$2"],0),makeConstList:makeConstList,lazy:lazy,lazyFinal:lazyFinal,updateHolder:updateHolder,convertToFastObject:convertToFastObject,updateTypes:updateTypes,setOrUpdateInterceptorsByTag:setOrUpdateInterceptorsByTag,setOrUpdateLeafTags:setOrUpdateLeafTags}}()
function initializeDeferredHunk(a){x=v.types.length
a(hunkHelpers,v,w,$)}var J={
pv(a,b,c,d){return{i:a,p:b,e:c,x:d}},
oi(a){var s,r,q,p,o,n=a[v.dispatchPropertyName]
if(n==null)if($.pt==null){A.w9()
n=a[v.dispatchPropertyName]}if(n!=null){s=n.p
if(!1===s)return n.i
if(!0===s)return a
r=Object.getPrototypeOf(a)
if(s===r)return n.i
if(n.e===r)throw A.c(A.qt("Return interceptor for "+A.D(s(a,n))))}q=a.constructor
if(q==null)p=null
else{o=$.nH
if(o==null)o=$.nH=v.getIsolateTag("_$dart_js")
p=q[o]}if(p!=null)return p
p=A.wd(a)
if(p!=null)return p
if(typeof a=="function")return B.cD
s=Object.getPrototypeOf(a)
if(s==null)return B.ba
if(s===Object.prototype)return B.ba
if(typeof q=="function"){o=$.nH
if(o==null)o=$.nH=v.getIsolateTag("_$dart_js")
Object.defineProperty(q,o,{value:B.b1,enumerable:false,writable:true,configurable:true})
return B.b1}return B.b1},
q1(a,b){if(a<0||a>4294967295)throw A.c(A.ax(a,0,4294967295,"length",null))
return J.tq(new Array(a),b)},
oR(a,b){if(a<0)throw A.c(A.bn("Length must be a non-negative integer: "+a,null))
return A.a(new Array(a),b.i("C<0>"))},
dv(a,b){if(a<0)throw A.c(A.bn("Length must be a non-negative integer: "+a,null))
return A.a(new Array(a),b.i("C<0>"))},
tq(a,b){var s=A.a(a,b.i("C<0>"))
s.$flags=1
return s},
tr(a,b){return J.pD(a,b)},
q2(a){if(a<256)switch(a){case 9:case 10:case 11:case 12:case 13:case 32:case 133:case 160:return!0
default:return!1}switch(a){case 5760:case 8192:case 8193:case 8194:case 8195:case 8196:case 8197:case 8198:case 8199:case 8200:case 8201:case 8202:case 8232:case 8233:case 8239:case 8287:case 12288:case 65279:return!0
default:return!1}},
ts(a,b){var s,r
for(s=a.length;b<s;){r=a.charCodeAt(b)
if(r!==32&&r!==13&&!J.q2(r))break;++b}return b},
tt(a,b){var s,r
for(;b>0;b=s){s=b-1
r=a.charCodeAt(s)
if(r!==32&&r!==13&&!J.q2(r))break}return b},
d3(a){if(typeof a=="number"){if(Math.floor(a)==a)return J.ez.prototype
return J.hk.prototype}if(typeof a=="string")return J.cg.prototype
if(a==null)return J.eA.prototype
if(typeof a=="boolean")return J.ey.prototype
if(Array.isArray(a))return J.C.prototype
if(typeof a!="object"){if(typeof a=="function")return J.bf.prototype
if(typeof a=="symbol")return J.dy.prototype
if(typeof a=="bigint")return J.dx.prototype
return a}if(a instanceof A.A)return a
return J.oi(a)},
X(a){if(typeof a=="string")return J.cg.prototype
if(a==null)return a
if(Array.isArray(a))return J.C.prototype
if(typeof a!="object"){if(typeof a=="function")return J.bf.prototype
if(typeof a=="symbol")return J.dy.prototype
if(typeof a=="bigint")return J.dx.prototype
return a}if(a instanceof A.A)return a
return J.oi(a)},
bc(a){if(a==null)return a
if(Array.isArray(a))return J.C.prototype
if(typeof a!="object"){if(typeof a=="function")return J.bf.prototype
if(typeof a=="symbol")return J.dy.prototype
if(typeof a=="bigint")return J.dx.prototype
return a}if(a instanceof A.A)return a
return J.oi(a)},
r9(a){if(typeof a=="number")return J.cI.prototype
if(a==null)return a
if(!(a instanceof A.A))return J.cq.prototype
return a},
ps(a){if(typeof a=="number")return J.cI.prototype
if(typeof a=="string")return J.cg.prototype
if(a==null)return a
if(!(a instanceof A.A))return J.cq.prototype
return a},
e0(a){if(typeof a=="string")return J.cg.prototype
if(a==null)return a
if(!(a instanceof A.A))return J.cq.prototype
return a},
e1(a){if(a==null)return a
if(typeof a!="object"){if(typeof a=="function")return J.bf.prototype
if(typeof a=="symbol")return J.dy.prototype
if(typeof a=="bigint")return J.dx.prototype
return a}if(a instanceof A.A)return a
return J.oi(a)},
rJ(a,b){if(typeof a=="number"&&typeof b=="number")return a+b
return J.ps(a).ap(a,b)},
rK(a,b){if(typeof a=="number"&&typeof b=="number")return a/b
return J.r9(a).aD(a,b)},
az(a,b){if(a==null)return b==null
if(typeof a!="object")return b!=null&&a===b
return J.d3(a).aw(a,b)},
rL(a,b){if(typeof a=="number"&&typeof b=="number")return a*b
return J.ps(a).P(a,b)},
rM(a,b){if(typeof a=="number"&&typeof b=="number")return a-b
return J.r9(a).aG(a,b)},
Y(a,b){if(typeof b==="number")if(Array.isArray(a)||typeof a=="string"||A.rc(a,a[v.dispatchPropertyName]))if(b>>>0===b&&b<a.length)return a[b]
return J.X(a).h(a,b)},
aY(a,b,c){if(typeof b==="number")if((Array.isArray(a)||A.rc(a,a[v.dispatchPropertyName]))&&!(a.$flags&2)&&b>>>0===b&&b<a.length)return a[b]=c
return J.bc(a).k(a,b,c)},
is(a,b,c){return J.e1(a).hK(a,b,c)},
it(a,b,c,d){return J.e1(a).ij(a,b,c,d)},
ae(a,b){return J.bc(a).T(a,b)},
pC(a,b){return J.e0(a).f6(a,b)},
rN(a,b){return J.bc(a).b2(a,b)},
rO(a,b,c){return J.e1(a).f7(a,b,c)},
rP(a,b,c){return J.e1(a).f8(a,b,c)},
rQ(a,b,c){return J.e1(a).f9(a,b,c)},
oy(a){return J.e1(a).fa(a)},
bm(a,b,c){return J.e1(a).ck(a,b,c)},
pD(a,b){return J.ps(a).A(a,b)},
pE(a,b){return J.bc(a).an(a,b)},
rR(a,b){return J.e0(a).B(a,b)},
rS(a,b,c){return J.bc(a).fj(a,b,c)},
e3(a){return J.bc(a).gH(a)},
by(a){return J.d3(a).gY(a)},
pF(a){return J.X(a).ga9(a)},
pG(a){return J.X(a).gaa(a)},
as(a){return J.bc(a).gJ(a)},
O(a){return J.X(a).gt(a)},
rT(a){return J.d3(a).gak(a)},
oz(a,b){return J.bc(a).R(a,b)},
bG(a,b,c){return J.bc(a).bc(a,b,c)},
rU(a,b,c){return J.e0(a).dH(a,b,c)},
pH(a,b){return J.bc(a).aN(a,b)},
pI(a,b){return J.bc(a).aq(a,b)},
oA(a,b){return J.e0(a).cQ(a,b)},
rV(a,b){return J.e0(a).U(a,b)},
rW(a,b,c){return J.e0(a).O(a,b,c)},
fP(a){return J.bc(a).aO(a)},
x(a){return J.d3(a).l(a)},
hf:function hf(){},
ey:function ey(){},
eA:function eA(){},
ap:function ap(){},
ch:function ch(){},
hB:function hB(){},
cq:function cq(){},
bf:function bf(){},
dx:function dx(){},
dy:function dy(){},
C:function C(a){this.$ti=a},
hj:function hj(){},
l2:function l2(a){this.$ti=a},
be:function be(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.d=null
_.$ti=c},
cI:function cI(){},
ez:function ez(){},
hk:function hk(){},
cg:function cg(){}},A={oT:function oT(){},
q5(a){return new A.cJ("Field '"+a+"' has not been initialized.")},
tv(a){return new A.cJ("Field '"+a+"' has already been initialized.")},
cp(a,b){a=a+b&536870911
a=a+((a&524287)<<10)&536870911
return a^a>>>6},
p7(a){a=a+((a&67108863)<<3)&536870911
a^=a>>>11
return a+((a&16383)<<15)&536870911},
cv(a,b,c){return a},
pu(a){var s,r
for(s=$.d1.length,r=0;r<s;++r)if(a===$.d1[r])return!0
return!1},
hK(a,b,c,d){A.eU(b,"start")
if(c!=null){A.eU(c,"end")
if(b>c)A.al(A.ax(b,0,c,"start",null))}return new A.fe(a,b,c,d.i("fe<0>"))},
oY(a,b,c,d){if(t.gw.b(a))return new A.ek(a,b,c.i("@<0>").ar(d).i("ek<1,2>"))
return new A.cM(a,b,c.i("@<0>").ar(d).i("cM<1,2>"))},
bX(){return new A.cm("No element")},
q_(){return new A.cm("Too few elements")},
hJ(a,b,c,d){if(c-b<=32)A.tQ(a,b,c,d)
else A.tP(a,b,c,d)},
tQ(a,b,c,d){var s,r,q,p,o
for(s=b+1,r=J.X(a);s<=c;++s){q=r.h(a,s)
p=s
for(;;){if(!(p>b&&d.$2(r.h(a,p-1),q)>0))break
o=p-1
r.k(a,p,r.h(a,o))
p=o}r.k(a,p,q)}},
tP(a3,a4,a5,a6){var s,r,q,p,o,n,m,l,k,j,i=B.c.a3(a5-a4+1,6),h=a4+i,g=a5-i,f=B.c.a3(a4+a5,2),e=f-i,d=f+i,c=J.X(a3),b=c.h(a3,h),a=c.h(a3,e),a0=c.h(a3,f),a1=c.h(a3,d),a2=c.h(a3,g)
if(a6.$2(b,a)>0){s=a
a=b
b=s}if(a6.$2(a1,a2)>0){s=a2
a2=a1
a1=s}if(a6.$2(b,a0)>0){s=a0
a0=b
b=s}if(a6.$2(a,a0)>0){s=a0
a0=a
a=s}if(a6.$2(b,a1)>0){s=a1
a1=b
b=s}if(a6.$2(a0,a1)>0){s=a1
a1=a0
a0=s}if(a6.$2(a,a2)>0){s=a2
a2=a
a=s}if(a6.$2(a,a0)>0){s=a0
a0=a
a=s}if(a6.$2(a1,a2)>0){s=a2
a2=a1
a1=s}c.k(a3,h,b)
c.k(a3,f,a0)
c.k(a3,g,a2)
c.k(a3,e,c.h(a3,a4))
c.k(a3,d,c.h(a3,a5))
r=a4+1
q=a5-1
p=J.az(a6.$2(a,a1),0)
if(p)for(o=r;o<=q;++o){n=c.h(a3,o)
m=a6.$2(n,a)
if(m===0)continue
if(m<0){if(o!==r){c.k(a3,o,c.h(a3,r))
c.k(a3,r,n)}++r}else for(;;){m=a6.$2(c.h(a3,q),a)
if(m>0){--q
continue}else{l=q-1
if(m<0){c.k(a3,o,c.h(a3,r))
k=r+1
c.k(a3,r,c.h(a3,q))
c.k(a3,q,n)
q=l
r=k
break}else{c.k(a3,o,c.h(a3,q))
c.k(a3,q,n)
q=l
break}}}}else for(o=r;o<=q;++o){n=c.h(a3,o)
if(a6.$2(n,a)<0){if(o!==r){c.k(a3,o,c.h(a3,r))
c.k(a3,r,n)}++r}else if(a6.$2(n,a1)>0)for(;;)if(a6.$2(c.h(a3,q),a1)>0){--q
if(q<o)break
continue}else{l=q-1
if(a6.$2(c.h(a3,q),a)<0){c.k(a3,o,c.h(a3,r))
k=r+1
c.k(a3,r,c.h(a3,q))
c.k(a3,q,n)
r=k}else{c.k(a3,o,c.h(a3,q))
c.k(a3,q,n)}q=l
break}}j=r-1
c.k(a3,a4,c.h(a3,j))
c.k(a3,j,a)
j=q+1
c.k(a3,a5,c.h(a3,j))
c.k(a3,j,a1)
A.hJ(a3,a4,r-2,a6)
A.hJ(a3,q+2,a5,a6)
if(p)return
if(r<h&&q>g){while(J.az(a6.$2(c.h(a3,r),a),0))++r
while(J.az(a6.$2(c.h(a3,q),a1),0))--q
for(o=r;o<=q;++o){n=c.h(a3,o)
if(a6.$2(n,a)===0){if(o!==r){c.k(a3,o,c.h(a3,r))
c.k(a3,r,n)}++r}else if(a6.$2(n,a1)===0)for(;;)if(a6.$2(c.h(a3,q),a1)===0){--q
if(q<o)break
continue}else{l=q-1
if(a6.$2(c.h(a3,q),a)<0){c.k(a3,o,c.h(a3,r))
k=r+1
c.k(a3,r,c.h(a3,q))
c.k(a3,q,n)
r=k}else{c.k(a3,o,c.h(a3,q))
c.k(a3,q,n)}q=l
break}}A.hJ(a3,r,q,a6)}else A.hJ(a3,r,q,a6)},
nn:function nn(a){this.a=0
this.b=a},
cJ:function cJ(a){this.a=a},
da:function da(a){this.a=a},
mN:function mN(){},
J:function J(){},
u:function u(){},
fe:function fe(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.$ti=d},
cL:function cL(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.d=null
_.$ti=c},
cM:function cM(a,b,c){this.a=a
this.b=b
this.$ti=c},
ek:function ek(a,b,c){this.a=a
this.b=b
this.$ti=c},
eE:function eE(a,b,c){var _=this
_.a=null
_.b=a
_.c=b
_.$ti=c},
h:function h(a,b,c){this.a=a
this.b=b
this.$ti=c},
aJ:function aJ(a,b,c){this.a=a
this.b=b
this.$ti=c},
fl:function fl(a,b,c){this.a=a
this.b=b
this.$ti=c},
bV:function bV(a,b,c){this.a=a
this.b=b
this.$ti=c},
eo:function eo(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=null
_.$ti=d},
em:function em(a){this.$ti=a},
es:function es(){},
hQ:function hQ(){},
dT:function dT(){},
eY:function eY(a,b){this.a=a
this.$ti=b},
hL:function hL(a){this.a=a},
oD(){throw A.c(A.a_("Cannot modify unmodifiable Map"))},
t3(){throw A.c(A.a_("Cannot modify constant Set"))},
rk(a){var s=v.mangledGlobalNames[a]
if(s!=null)return s
return"minified:"+a},
rc(a,b){var s
if(b!=null){s=b.x
if(s!=null)return s}return t.aU.b(a)},
D(a){var s
if(typeof a=="string")return a
if(typeof a=="number"){if(a!==0)return""+a}else if(!0===a)return"true"
else if(!1===a)return"false"
else if(a==null)return"null"
s=J.x(a)
return s},
hC(a){var s,r=$.qe
if(r==null)r=$.qe=Symbol("identityHashCode")
s=a[r]
if(s==null){s=Math.random()*0x3fffffff|0
a[r]=s}return s},
a4(a,b){var s,r=/^\s*[+-]?((0x[a-f0-9]+)|(\d+)|([a-z0-9]+))\s*$/i.exec(a)
if(r==null)return null
s=r[3]
if(s!=null)return parseInt(a,10)
if(r[2]!=null)return parseInt(a,16)
return null},
aH(a){var s,r
if(!/^\s*[+-]?(?:Infinity|NaN|(?:\.\d+|\d+(?:\.\d*)?)(?:[eE][+-]?\d+)?)\s*$/.test(a))return null
s=parseFloat(a)
if(isNaN(s)){r=B.a.V(a)
if(r==="NaN"||r==="+NaN"||r==="-NaN")return s
return null}return s},
eS(a){var s,r,q,p
if(a instanceof A.A)return A.bl(A.bO(a),null)
s=J.d3(a)
if(s===B.cB||s===B.cE||t.ak.b(a)){r=B.b6(a)
if(r!=="Object"&&r!=="")return r
q=a.constructor
if(typeof q=="function"){p=q.name
if(typeof p=="string"&&p!=="Object"&&p!=="")return p}}return A.bl(A.bO(a),null)},
qg(a){var s,r,q
if(a==null||typeof a=="number"||A.fI(a))return J.x(a)
if(typeof a=="string")return JSON.stringify(a)
if(a instanceof A.cz)return a.l(0)
if(a instanceof A.fA)return a.f2(!0)
s=$.rH()
for(r=0;r<1;++r){q=s[r].jc(a)
if(q!=null)return q}return"Instance of '"+A.eS(a)+"'"},
tD(){return Date.now()},
tF(){var s,r
if($.mm!==0)return
$.mm=1000
if(typeof window=="undefined")return
s=window
if(s==null)return
if(!!s.dartUseDateNowForTicks)return
r=s.performance
if(r==null)return
if(typeof r.now!="function")return
$.mm=1e6
$.cN=new A.ml(r)},
tG(a,b,c){var s,r,q,p
if(c<=500&&b===0&&c===a.length)return String.fromCharCode.apply(null,a)
for(s=b,r="";s<c;s=q){q=s+500
p=q<c?q:c
r+=String.fromCharCode.apply(null,a.subarray(s,p))}return r},
au(a){var s
if(a<=65535)return String.fromCharCode(a)
if(a<=1114111){s=a-65536
return String.fromCharCode((B.c.bV(s,10)|55296)>>>0,s&1023|56320)}throw A.c(A.ax(a,0,1114111,null,null))},
tH(a,b,c,d,e,f,g,h,i){var s,r,q,p=b-1
if(0<=a&&a<100){a+=400
p-=4800}s=B.c.a7(h,1000)
g+=B.c.a3(h-s,1000)
r=i?Date.UTC(a,p,c,d,e,f,g):new Date(a,p,c,d,e,f,g).valueOf()
q=!0
if(!isNaN(r))if(!(r<-864e13))if(!(r>864e13))q=r===864e13&&s!==0
if(q)return null
return r},
bi(a){if(a.date===void 0)a.date=new Date(a.a)
return a.date},
b2(a){return a.c?A.bi(a).getUTCFullYear()+0:A.bi(a).getFullYear()+0},
bB(a){return a.c?A.bi(a).getUTCMonth()+1:A.bi(a).getMonth()+1},
bI(a){return a.c?A.bi(a).getUTCDate()+0:A.bi(a).getDate()+0},
dJ(a){return a.c?A.bi(a).getUTCHours()+0:A.bi(a).getHours()+0},
eQ(a){return a.c?A.bi(a).getUTCMinutes()+0:A.bi(a).getMinutes()+0},
eR(a){return a.c?A.bi(a).getUTCSeconds()+0:A.bi(a).getSeconds()+0},
qf(a){return a.c?A.bi(a).getUTCMilliseconds()+0:A.bi(a).getMilliseconds()+0},
tE(a){var s=a.$thrownJsError
if(s==null)return null
return A.bN(s)},
p0(a,b){var s
if(a.$thrownJsError==null){s=new Error()
A.aC(a,s)
a.$thrownJsError=s
s.stack=b.l(0)}},
od(a,b){var s,r="index"
if(!A.fJ(b))return new A.bz(!0,b,r,null)
s=J.O(a)
if(b<0||b>=s)return A.oP(b,s,a,r)
return A.mH(b,r)},
w3(a,b,c){if(a>c)return A.ax(a,0,c,"start",null)
if(b!=null)if(b<a||b>c)return A.ax(b,a,c,"end",null)
return new A.bz(!0,b,"end",null)},
vI(a){return new A.bz(!0,a,null,null)},
c(a){return A.aC(a,new Error())},
aC(a,b){var s
if(a==null)a=new A.c5()
b.dartException=a
s=A.wq
if("defineProperty" in Object){Object.defineProperty(b,"message",{get:s})
b.name=""}else b.toString=s
return b},
wq(){return J.x(this.dartException)},
al(a,b){throw A.aC(a,b==null?new Error():b)},
i(a,b,c){var s
if(b==null)b=0
if(c==null)c=0
s=Error()
A.al(A.uY(a,b,c),s)},
uY(a,b,c){var s,r,q,p,o,n,m,l,k
if(typeof b=="string")s=b
else{r="[]=;add;removeWhere;retainWhere;removeRange;setRange;setInt8;setInt16;setInt32;setUint8;setUint16;setUint32;setFloat32;setFloat64".split(";")
q=r.length
p=b
if(p>q){c=p/q|0
p%=q}s=r[p]}o=typeof c=="string"?c:"modify;remove from;add to".split(";")[c]
n=t.j.b(a)?"list":"ByteData"
m=a.$flags|0
l="a "
if((m&4)!==0)k="constant "
else if((m&2)!==0){k="unmodifiable "
l="an "}else k=(m&1)!==0?"fixed-length ":""
return new A.fi("'"+s+"': Cannot "+o+" "+l+k+n)},
n(a){throw A.c(A.aA(a))},
c6(a){var s,r,q,p,o,n
a=A.iq(a.replace(String({}),"$receiver$"))
s=a.match(/\\\$[a-zA-Z]+\\\$/g)
if(s==null)s=A.a([],t.s)
r=s.indexOf("\\$arguments\\$")
q=s.indexOf("\\$argumentsExpr\\$")
p=s.indexOf("\\$expr\\$")
o=s.indexOf("\\$method\\$")
n=s.indexOf("\\$receiver\\$")
return new A.n7(a.replace(new RegExp("\\\\\\$arguments\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$argumentsExpr\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$expr\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$method\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$receiver\\\\\\$","g"),"((?:x|[^x])*)"),r,q,p,o,n)},
n8(a){return function($expr$){var $argumentsExpr$="$arguments$"
try{$expr$.$method$($argumentsExpr$)}catch(s){return s.message}}(a)},
qs(a){return function($expr$){try{$expr$.$method$}catch(s){return s.message}}(a)},
oV(a,b){var s=b==null,r=s?null:b.method
return new A.hl(a,r,s?null:b.receiver)},
aV(a){if(a==null)return new A.lZ(a)
if(a instanceof A.en)return A.cx(a,a.a)
if(typeof a!=="object")return a
if("dartException" in a)return A.cx(a,a.dartException)
return A.vH(a)},
cx(a,b){if(t.Q.b(b))if(b.$thrownJsError==null)b.$thrownJsError=a
return b},
vH(a){var s,r,q,p,o,n,m,l,k,j,i,h,g
if(!("message" in a))return a
s=a.message
if("number" in a&&typeof a.number=="number"){r=a.number
q=r&65535
if((B.c.bV(r,16)&8191)===10)switch(q){case 438:return A.cx(a,A.oV(A.D(s)+" (Error "+q+")",null))
case 445:case 5007:A.D(s)
return A.cx(a,new A.eM())}}if(a instanceof TypeError){p=$.rr()
o=$.rs()
n=$.rt()
m=$.ru()
l=$.rx()
k=$.ry()
j=$.rw()
$.rv()
i=$.rA()
h=$.rz()
g=p.aZ(s)
if(g!=null)return A.cx(a,A.oV(s,g))
else{g=o.aZ(s)
if(g!=null){g.method="call"
return A.cx(a,A.oV(s,g))}else if(n.aZ(s)!=null||m.aZ(s)!=null||l.aZ(s)!=null||k.aZ(s)!=null||j.aZ(s)!=null||m.aZ(s)!=null||i.aZ(s)!=null||h.aZ(s)!=null)return A.cx(a,new A.eM())}return A.cx(a,new A.hP(typeof s=="string"?s:""))}if(a instanceof RangeError){if(typeof s=="string"&&s.indexOf("call stack")!==-1)return new A.fa()
s=function(b){try{return String(b)}catch(f){}return null}(a)
return A.cx(a,new A.bz(!1,null,null,typeof s=="string"?s.replace(/^RangeError:\s*/,""):s))}if(typeof InternalError=="function"&&a instanceof InternalError)if(typeof s=="string"&&s==="too much recursion")return new A.fa()
return a},
bN(a){var s
if(a instanceof A.en)return a.b
if(a==null)return new A.fC(a)
s=a.$cachedTrace
if(s!=null)return s
s=new A.fC(a)
if(typeof a==="object")a.$cachedTrace=s
return s},
rf(a){if(a==null)return J.by(a)
if(typeof a=="object")return A.hC(a)
return J.by(a)},
w6(a,b){var s,r,q,p=a.length
for(s=0;s<p;s=q){r=s+1
q=r+1
b.k(0,a[s],a[r])}return b},
v9(a,b,c,d,e,f){switch(b){case 0:return a.$0()
case 1:return a.$1(c)
case 2:return a.$2(c,d)
case 3:return a.$3(c,d,e)
case 4:return a.$4(c,d,e,f)}throw A.c(A.q("Unsupported number of arguments for wrapped closure"))},
fN(a,b){var s=a.$identity
if(!!s)return s
s=A.w0(a,b)
a.$identity=s
return s},
w0(a,b){var s
switch(b){case 0:s=a.$0
break
case 1:s=a.$1
break
case 2:s=a.$2
break
case 3:s=a.$3
break
case 4:s=a.$4
break
default:s=null}if(s!=null)return s.bind(a)
return function(c,d,e){return function(f,g,h,i){return e(c,d,f,g,h,i)}}(a,b,A.v9)},
t2(a2){var s,r,q,p,o,n,m,l,k,j,i=a2.co,h=a2.iS,g=a2.iI,f=a2.nDA,e=a2.aI,d=a2.fs,c=a2.cs,b=d[0],a=c[0],a0=i[b],a1=a2.fT
a1.toString
s=h?Object.create(new A.mP().constructor.prototype):Object.create(new A.e8(null,null).constructor.prototype)
s.$initialize=s.constructor
r=h?function static_tear_off(){this.$initialize()}:function tear_off(a3,a4){this.$initialize(a3,a4)}
s.constructor=r
r.prototype=s
s.$_name=b
s.$_target=a0
q=!h
if(q)p=A.pO(b,a0,g,f)
else{s.$static_name=b
p=a0}s.$S=A.rZ(a1,h,g)
s[a]=p
for(o=p,n=1;n<d.length;++n){m=d[n]
if(typeof m=="string"){l=i[m]
k=m
m=l}else k=""
j=c[n]
if(j!=null){if(q)m=A.pO(k,m,g,f)
s[j]=m}if(n===e)o=m}s.$C=o
s.$R=a2.rC
s.$D=a2.dV
return r},
rZ(a,b,c){if(typeof a=="number")return a
if(typeof a=="string"){if(b)throw A.c("Cannot compute signature for static tearoff.")
return function(d,e){return function(){return e(this,d)}}(a,A.rX)}throw A.c("Error in functionType of tearoff")},
t_(a,b,c,d){var s=A.pN
switch(b?-1:a){case 0:return function(e,f){return function(){return f(this)[e]()}}(c,s)
case 1:return function(e,f){return function(g){return f(this)[e](g)}}(c,s)
case 2:return function(e,f){return function(g,h){return f(this)[e](g,h)}}(c,s)
case 3:return function(e,f){return function(g,h,i){return f(this)[e](g,h,i)}}(c,s)
case 4:return function(e,f){return function(g,h,i,j){return f(this)[e](g,h,i,j)}}(c,s)
case 5:return function(e,f){return function(g,h,i,j,k){return f(this)[e](g,h,i,j,k)}}(c,s)
default:return function(e,f){return function(){return e.apply(f(this),arguments)}}(d,s)}},
pO(a,b,c,d){if(c)return A.t1(a,b,d)
return A.t_(b.length,d,a,b)},
t0(a,b,c,d){var s=A.pN,r=A.rY
switch(b?-1:a){case 0:throw A.c(new A.hH("Intercepted function with no arguments."))
case 1:return function(e,f,g){return function(){return f(this)[e](g(this))}}(c,r,s)
case 2:return function(e,f,g){return function(h){return f(this)[e](g(this),h)}}(c,r,s)
case 3:return function(e,f,g){return function(h,i){return f(this)[e](g(this),h,i)}}(c,r,s)
case 4:return function(e,f,g){return function(h,i,j){return f(this)[e](g(this),h,i,j)}}(c,r,s)
case 5:return function(e,f,g){return function(h,i,j,k){return f(this)[e](g(this),h,i,j,k)}}(c,r,s)
case 6:return function(e,f,g){return function(h,i,j,k,l){return f(this)[e](g(this),h,i,j,k,l)}}(c,r,s)
default:return function(e,f,g){return function(){var q=[g(this)]
Array.prototype.push.apply(q,arguments)
return e.apply(f(this),q)}}(d,r,s)}},
t1(a,b,c){var s,r
if($.pL==null)$.pL=A.pK("interceptor")
if($.pM==null)$.pM=A.pK("receiver")
s=b.length
r=A.t0(s,c,a,b)
return r},
pr(a){return A.t2(a)},
rX(a,b){return A.fH(v.typeUniverse,A.bO(a.a),b)},
pN(a){return a.a},
rY(a){return a.b},
pK(a){var s,r,q,p=new A.e8("receiver","interceptor"),o=Object.getOwnPropertyNames(p)
o.$flags=1
s=o
for(o=s.length,r=0;r<o;++r){q=s[r]
if(p[q]===a)return q}throw A.c(A.bn("Field name "+a+" not found.",null))},
ra(a){return v.getIsolateTag(a)},
wd(a){var s,r,q,p,o,n=$.rb.$1(a),m=$.oe[n]
if(m!=null){Object.defineProperty(a,v.dispatchPropertyName,{value:m,enumerable:false,writable:true,configurable:true})
return m.i}s=$.om[n]
if(s!=null)return s
r=v.interceptorsByTag[n]
if(r==null){q=$.r0.$2(a,n)
if(q!=null){m=$.oe[q]
if(m!=null){Object.defineProperty(a,v.dispatchPropertyName,{value:m,enumerable:false,writable:true,configurable:true})
return m.i}s=$.om[q]
if(s!=null)return s
r=v.interceptorsByTag[q]
n=q}}if(r==null)return null
s=r.prototype
p=n[0]
if(p==="!"){m=A.op(s)
$.oe[n]=m
Object.defineProperty(a,v.dispatchPropertyName,{value:m,enumerable:false,writable:true,configurable:true})
return m.i}if(p==="~"){$.om[n]=s
return s}if(p==="-"){o=A.op(s)
Object.defineProperty(Object.getPrototypeOf(a),v.dispatchPropertyName,{value:o,enumerable:false,writable:true,configurable:true})
return o.i}if(p==="+")return A.rh(a,s)
if(p==="*")throw A.c(A.qt(n))
if(v.leafTags[n]===true){o=A.op(s)
Object.defineProperty(Object.getPrototypeOf(a),v.dispatchPropertyName,{value:o,enumerable:false,writable:true,configurable:true})
return o.i}else return A.rh(a,s)},
rh(a,b){var s=Object.getPrototypeOf(a)
Object.defineProperty(s,v.dispatchPropertyName,{value:J.pv(b,s,null,null),enumerable:false,writable:true,configurable:true})
return b},
op(a){return J.pv(a,!1,null,!!a.$ibg)},
we(a,b,c){var s=b.prototype
if(v.leafTags[a]===true)return A.op(s)
else return J.pv(s,c,null,null)},
w9(){if(!0===$.pt)return
$.pt=!0
A.wa()},
wa(){var s,r,q,p,o,n,m,l
$.oe=Object.create(null)
$.om=Object.create(null)
A.w8()
s=v.interceptorsByTag
r=Object.getOwnPropertyNames(s)
if(typeof window!="undefined"){window
q=function(){}
for(p=0;p<r.length;++p){o=r[p]
n=$.ri.$1(o)
if(n!=null){m=A.we(o,s[o],n)
if(m!=null){Object.defineProperty(n,v.dispatchPropertyName,{value:m,enumerable:false,writable:true,configurable:true})
q.prototype=n}}}}for(p=0;p<r.length;++p){o=r[p]
if(/^[A-Za-z_]/.test(o)){l=s[o]
s["!"+o]=l
s["~"+o]=l
s["-"+o]=l
s["+"+o]=l
s["*"+o]=l}}},
w8(){var s,r,q,p,o,n,m=B.cp()
m=A.e_(B.cq,A.e_(B.cr,A.e_(B.b7,A.e_(B.b7,A.e_(B.cs,A.e_(B.ct,A.e_(B.cu(B.b6),m)))))))
if(typeof dartNativeDispatchHooksTransformer!="undefined"){s=dartNativeDispatchHooksTransformer
if(typeof s=="function")s=[s]
if(Array.isArray(s))for(r=0;r<s.length;++r){q=s[r]
if(typeof q=="function")m=q(m)||m}}p=m.getTag
o=m.getUnknownTag
n=m.prototypeForTag
$.rb=new A.oj(p)
$.r0=new A.ok(o)
$.ri=new A.ol(n)},
e_(a,b){return a(b)||b},
w2(a,b){var s=b.length,r=v.rttc[""+s+";"+a]
if(r==null)return null
if(s===0)return r
if(s===r.length)return r.apply(null,b)
return r(b)},
oS(a,b,c,d,e,f){var s=b?"m":"",r=c?"":"i",q=d?"u":"",p=e?"s":"",o=function(g,h){try{return new RegExp(g,h)}catch(n){return n}}(a,s+r+q+p+f)
if(o instanceof RegExp)return o
throw A.c(A.cf("Illegal RegExp pattern ("+String(o)+")",a,null))},
wm(a,b,c){var s=a.indexOf(b,c)
return s>=0},
r4(a){if(a.indexOf("$",0)>=0)return a.replace(/\$/g,"$$$$")
return a},
iq(a){if(/[[\]{}()*+?.\\^$|]/.test(a))return a.replace(/[[\]{}()*+?.\\^$|]/g,"\\$&")
return a},
T(a,b,c){var s
if(typeof b=="string")return A.wo(a,b,c)
if(b instanceof A.dw){s=b.geB()
s.lastIndex=0
return a.replace(s,A.r4(c))}return A.wn(a,b,c)},
wn(a,b,c){var s,r,q,p
for(s=J.pC(b,a),s=s.gJ(s),r=0,q="";s.p();){p=s.gD()
q=q+a.substring(r,p.gcR())+c
r=p.gcq()}s=q+a.substring(r)
return s.charCodeAt(0)==0?s:s},
wo(a,b,c){var s,r,q
if(b===""){if(a==="")return c
s=a.length
for(r=c,q=0;q<s;++q)r=r+a[q]+c
return r.charCodeAt(0)==0?r:r}if(a.indexOf(b,0)<0)return a
if(a.length<500||c.indexOf("$",0)>=0)return a.split(b).join(c)
return a.replace(new RegExp(A.iq(b),"g"),A.r4(c))},
ia:function ia(a,b){this.a=a
this.b=b},
ec:function ec(){},
ee:function ee(a,b,c){this.a=a
this.b=b
this.$ti=c},
cV:function cV(a,b){this.a=a
this.$ti=b},
cW:function cW(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.d=null
_.$ti=c},
ed:function ed(){},
bR:function bR(a,b,c){this.a=a
this.b=b
this.$ti=c},
ml:function ml(a){this.a=a},
f1:function f1(){},
n7:function n7(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f},
eM:function eM(){},
hl:function hl(a,b,c){this.a=a
this.b=b
this.c=c},
hP:function hP(a){this.a=a},
lZ:function lZ(a){this.a=a},
en:function en(a,b){this.a=a
this.b=b},
fC:function fC(a){this.a=a
this.b=null},
cz:function cz(){},
iL:function iL(){},
iM:function iM(){},
n5:function n5(){},
mP:function mP(){},
e8:function e8(a,b){this.a=a
this.b=b},
hH:function hH(a){this.a=a},
bZ:function bZ(a){var _=this
_.a=0
_.f=_.e=_.d=_.c=_.b=null
_.r=0
_.$ti=a},
lN:function lN(a){this.a=a},
lR:function lR(a,b){var _=this
_.a=a
_.b=b
_.d=_.c=null},
aB:function aB(a,b){this.a=a
this.$ti=b},
aL:function aL(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=null
_.$ti=d},
b1:function b1(a,b){this.a=a
this.$ti=b},
ao:function ao(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=null
_.$ti=d},
an:function an(a,b){this.a=a
this.$ti=b},
eD:function eD(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=null
_.$ti=d},
oj:function oj(a){this.a=a},
ok:function ok(a){this.a=a},
ol:function ol(a){this.a=a},
fA:function fA(){},
i9:function i9(){},
dw:function dw(a,b){var _=this
_.a=a
_.b=b
_.e=_.d=_.c=null},
dW:function dW(a){this.b=a},
hV:function hV(a,b,c){this.a=a
this.b=b
this.c=c},
hW:function hW(a,b,c){var _=this
_.a=a
_.b=b
_.c=c
_.d=null},
dQ:function dQ(a,b){this.a=a
this.c=b},
id:function id(a,b,c){this.a=a
this.b=b
this.c=c},
ie:function ie(a,b,c){var _=this
_.a=a
_.b=b
_.c=c
_.d=null},
wp(a){throw A.aC(new A.cJ("Field '"+a+"' has been assigned during initialization."),new Error())},
b(){throw A.aC(A.q5(""),new Error())},
bd(){throw A.aC(A.tv(""),new Error())},
qv(){var s=new A.nm()
return s.b=s},
nm:function nm(){this.b=null},
d_(a,b,c){},
bx(a){var s,r,q
if(t.aP.b(a))return a
s=J.X(a)
r=A.a9(s.gt(a),null,!1,t.z)
for(q=0;q<s.gt(a);++q)r[q]=s.h(a,q)
return r},
tx(a,b,c){var s
A.d_(a,b,c)
s=new DataView(a,b,c)
return s},
ty(a,b,c){A.d_(a,b,c)
return new Float64Array(a,b,c)},
tz(a,b,c){A.d_(a,b,c)
return new Int32Array(a,b,c)},
lX(a){return new Uint8Array(a)},
tA(a,b,c){A.d_(a,b,c)
return c==null?new Uint8Array(a,b):new Uint8Array(a,b,c)},
c9(a,b,c){if(a>>>0!==a||a>=c)throw A.c(A.od(b,a))},
pg(a,b,c){var s
if(!(a>>>0!==a))s=b>>>0!==b||a>b||b>c
else s=!0
if(s)throw A.c(A.w3(a,b,c))
return b},
dB:function dB(){},
eJ:function eJ(){},
nW:function nW(a){this.a=a},
eG:function eG(){},
dC:function dC(){},
cj:function cj(){},
bh:function bh(){},
hn:function hn(){},
eH:function eH(){},
ho:function ho(){},
eI:function eI(){},
hp:function hp(){},
hq:function hq(){},
hr:function hr(){},
eK:function eK(){},
eL:function eL(){},
fw:function fw(){},
fx:function fx(){},
fy:function fy(){},
fz:function fz(){},
p2(a,b){var s=b.c
return s==null?b.c=A.fF(a,"b8",[b.x]):s},
ql(a){var s=a.w
if(s===6||s===7)return A.ql(a.x)
return s===11||s===12},
tO(a){return a.as},
ca(a){return A.nV(v.typeUniverse,a,!1)},
d0(a1,a2,a3,a4){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0=a2.w
switch(a0){case 5:case 1:case 2:case 3:case 4:return a2
case 6:s=a2.x
r=A.d0(a1,s,a3,a4)
if(r===s)return a2
return A.qF(a1,r,!0)
case 7:s=a2.x
r=A.d0(a1,s,a3,a4)
if(r===s)return a2
return A.qE(a1,r,!0)
case 8:q=a2.y
p=A.dZ(a1,q,a3,a4)
if(p===q)return a2
return A.fF(a1,a2.x,p)
case 9:o=a2.x
n=A.d0(a1,o,a3,a4)
m=a2.y
l=A.dZ(a1,m,a3,a4)
if(n===o&&l===m)return a2
return A.pd(a1,n,l)
case 10:k=a2.x
j=a2.y
i=A.dZ(a1,j,a3,a4)
if(i===j)return a2
return A.qG(a1,k,i)
case 11:h=a2.x
g=A.d0(a1,h,a3,a4)
f=a2.y
e=A.vE(a1,f,a3,a4)
if(g===h&&e===f)return a2
return A.qD(a1,g,e)
case 12:d=a2.y
a4+=d.length
c=A.dZ(a1,d,a3,a4)
o=a2.x
n=A.d0(a1,o,a3,a4)
if(c===d&&n===o)return a2
return A.pe(a1,n,c,!0)
case 13:b=a2.x
if(b<a4)return a2
a=a3[b-a4]
if(a==null)return a2
return a
default:throw A.c(A.e5("Attempted to substitute unexpected RTI kind "+a0))}},
dZ(a,b,c,d){var s,r,q,p,o=b.length,n=A.o_(o)
for(s=!1,r=0;r<o;++r){q=b[r]
p=A.d0(a,q,c,d)
if(p!==q)s=!0
n[r]=p}return s?n:b},
vF(a,b,c,d){var s,r,q,p,o,n,m=b.length,l=A.o_(m)
for(s=!1,r=0;r<m;r+=3){q=b[r]
p=b[r+1]
o=b[r+2]
n=A.d0(a,o,c,d)
if(n!==o)s=!0
l.splice(r,3,q,p,n)}return s?l:b},
vE(a,b,c,d){var s,r=b.a,q=A.dZ(a,r,c,d),p=b.b,o=A.dZ(a,p,c,d),n=b.c,m=A.vF(a,n,c,d)
if(q===r&&o===p&&m===n)return b
s=new A.i4()
s.a=q
s.b=o
s.c=m
return s},
a(a,b){a[v.arrayRti]=b
return a},
r2(a){var s=a.$S
if(s!=null){if(typeof s=="number")return A.w7(s)
return a.$S()}return null},
wb(a,b){var s
if(A.ql(b))if(a instanceof A.cz){s=A.r2(a)
if(s!=null)return s}return A.bO(a)},
bO(a){if(a instanceof A.A)return A.E(a)
if(Array.isArray(a))return A.z(a)
return A.pj(J.d3(a))},
z(a){var s=a[v.arrayRti],r=t.gn
if(s==null)return r
if(s.constructor!==r.constructor)return r
return s},
E(a){var s=a.$ti
return s!=null?s:A.pj(a)},
pj(a){var s=a.constructor,r=s.$ccache
if(r!=null)return r
return A.v6(a,s)},
v6(a,b){var s=a instanceof A.cz?Object.getPrototypeOf(Object.getPrototypeOf(a)).constructor:b,r=A.uD(v.typeUniverse,s.name)
b.$ccache=r
return r},
w7(a){var s,r=v.types,q=r[a]
if(typeof q=="string"){s=A.nV(v.typeUniverse,q,!1)
r[a]=s
return s}return q},
ip(a){return A.d2(A.E(a))},
pq(a){var s
if(a instanceof A.fA)return A.w4(a.$r,a.ep())
s=a instanceof A.cz?A.r2(a):null
if(s!=null)return s
if(t.dm.b(a))return J.rT(a).a
if(Array.isArray(a))return A.z(a)
return A.bO(a)},
d2(a){var s=a.r
return s==null?a.r=new A.nU(a):s},
w4(a,b){var s,r,q=b,p=q.length
if(p===0)return t.bQ
s=A.fH(v.typeUniverse,A.pq(q[0]),"@<0>")
for(r=1;r<p;++r)s=A.qH(v.typeUniverse,s,A.pq(q[r]))
return A.fH(v.typeUniverse,s,a)},
bF(a){return A.d2(A.nV(v.typeUniverse,a,!1))},
v5(a){var s=this
s.b=A.vC(s)
return s.b(a)},
vC(a){var s,r,q,p
if(a===t.C)return A.vf
if(A.d5(a))return A.vj
s=a.w
if(s===6)return A.v1
if(s===1)return A.qR
if(s===7)return A.va
r=A.vB(a)
if(r!=null)return r
if(s===8){q=a.x
if(a.y.every(A.d5)){a.f="$i"+q
if(q==="t")return A.vd
if(a===t.eH)return A.vc
return A.vi}}else if(s===10){p=A.w2(a.x,a.y)
return p==null?A.qR:p}return A.v_},
vB(a){if(a.w===8){if(a===t.S)return A.fJ
if(a===t.i||a===t.di)return A.ve
if(a===t.N)return A.vh
if(a===t.y)return A.fI}return null},
v4(a){var s=this,r=A.uZ
if(A.d5(s))r=A.uS
else if(s===t.C)r=A.uQ
else if(A.e2(s)){r=A.v0
if(s===t.h6)r=A.uM
else if(s===t.T)r=A.uR
else if(s===t.fQ)r=A.uJ
else if(s===t.e6)r=A.uP
else if(s===t.cD)r=A.uL
else if(s===t.an)r=A.uO}else if(s===t.S)r=A.qL
else if(s===t.N)r=A.il
else if(s===t.y)r=A.uI
else if(s===t.di)r=A.ik
else if(s===t.i)r=A.uK
else if(s===t.eH)r=A.uN
s.a=r
return s.a(a)},
v_(a){var s=this
if(a==null)return A.e2(s)
return A.wc(v.typeUniverse,A.wb(a,s),s)},
v1(a){if(a==null)return!0
return this.x.b(a)},
vi(a){var s,r=this
if(a==null)return A.e2(r)
s=r.f
if(a instanceof A.A)return!!a[s]
return!!J.d3(a)[s]},
vd(a){var s,r=this
if(a==null)return A.e2(r)
if(typeof a!="object")return!1
if(Array.isArray(a))return!0
s=r.f
if(a instanceof A.A)return!!a[s]
return!!J.d3(a)[s]},
vc(a){var s=this
if(a==null)return!1
if(typeof a=="object"){if(a instanceof A.A)return!!a[s.f]
return!0}if(typeof a=="function")return!0
return!1},
qQ(a){if(typeof a=="object"){if(a instanceof A.A)return t.eH.b(a)
return!0}if(typeof a=="function")return!0
return!1},
uZ(a){var s=this
if(a==null){if(A.e2(s))return a}else if(s.b(a))return a
throw A.aC(A.qM(a,s),new Error())},
v0(a){var s=this
if(a==null||s.b(a))return a
throw A.aC(A.qM(a,s),new Error())},
qM(a,b){return new A.fD("TypeError: "+A.qw(a,A.bl(b,null)))},
qw(a,b){return A.h4(a)+": type '"+A.bl(A.pq(a),null)+"' is not a subtype of type '"+b+"'"},
bw(a,b){return new A.fD("TypeError: "+A.qw(a,b))},
va(a){var s=this
return s.x.b(a)||A.p2(v.typeUniverse,s).b(a)},
vf(a){return a!=null},
uQ(a){if(a!=null)return a
throw A.aC(A.bw(a,"Object"),new Error())},
vj(a){return!0},
uS(a){return a},
qR(a){return!1},
fI(a){return!0===a||!1===a},
uI(a){if(!0===a)return!0
if(!1===a)return!1
throw A.aC(A.bw(a,"bool"),new Error())},
uJ(a){if(!0===a)return!0
if(!1===a)return!1
if(a==null)return a
throw A.aC(A.bw(a,"bool?"),new Error())},
uK(a){if(typeof a=="number")return a
throw A.aC(A.bw(a,"double"),new Error())},
uL(a){if(typeof a=="number")return a
if(a==null)return a
throw A.aC(A.bw(a,"double?"),new Error())},
fJ(a){return typeof a=="number"&&Math.floor(a)===a},
qL(a){if(typeof a=="number"&&Math.floor(a)===a)return a
throw A.aC(A.bw(a,"int"),new Error())},
uM(a){if(typeof a=="number"&&Math.floor(a)===a)return a
if(a==null)return a
throw A.aC(A.bw(a,"int?"),new Error())},
ve(a){return typeof a=="number"},
ik(a){if(typeof a=="number")return a
throw A.aC(A.bw(a,"num"),new Error())},
uP(a){if(typeof a=="number")return a
if(a==null)return a
throw A.aC(A.bw(a,"num?"),new Error())},
vh(a){return typeof a=="string"},
il(a){if(typeof a=="string")return a
throw A.aC(A.bw(a,"String"),new Error())},
uR(a){if(typeof a=="string")return a
if(a==null)return a
throw A.aC(A.bw(a,"String?"),new Error())},
uN(a){if(A.qQ(a))return a
throw A.aC(A.bw(a,"JSObject"),new Error())},
uO(a){if(a==null)return a
if(A.qQ(a))return a
throw A.aC(A.bw(a,"JSObject?"),new Error())},
qY(a,b){var s,r,q
for(s="",r="",q=0;q<a.length;++q,r=", ")s+=r+A.bl(a[q],b)
return s},
vr(a,b){var s,r,q,p,o,n,m=a.x,l=a.y
if(""===m)return"("+A.qY(l,b)+")"
s=l.length
r=m.split(",")
q=r.length-s
for(p="(",o="",n=0;n<s;++n,o=", "){p+=o
if(q===0)p+="{"
p+=A.bl(l[n],b)
if(q>=0)p+=" "+r[q];++q}return p+"})"},
qN(a1,a2,a3){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a=", ",a0=null
if(a3!=null){s=a3.length
if(a2==null)a2=A.a([],t.s)
else a0=a2.length
r=a2.length
for(q=s;q>0;--q)a2.push("T"+(r+q))
for(p=t.X,o="<",n="",q=0;q<s;++q,n=a){o=o+n+a2[a2.length-1-q]
m=a3[q]
l=m.w
if(!(l===2||l===3||l===4||l===5||m===p))o+=" extends "+A.bl(m,a2)}o+=">"}else o=""
p=a1.x
k=a1.y
j=k.a
i=j.length
h=k.b
g=h.length
f=k.c
e=f.length
d=A.bl(p,a2)
for(c="",b="",q=0;q<i;++q,b=a)c+=b+A.bl(j[q],a2)
if(g>0){c+=b+"["
for(b="",q=0;q<g;++q,b=a)c+=b+A.bl(h[q],a2)
c+="]"}if(e>0){c+=b+"{"
for(b="",q=0;q<e;q+=3,b=a){c+=b
if(f[q+1])c+="required "
c+=A.bl(f[q+2],a2)+" "+f[q]}c+="}"}if(a0!=null){a2.toString
a2.length=a0}return o+"("+c+") => "+d},
bl(a,b){var s,r,q,p,o,n,m=a.w
if(m===5)return"erased"
if(m===2)return"dynamic"
if(m===3)return"void"
if(m===1)return"Never"
if(m===4)return"any"
if(m===6){s=a.x
r=A.bl(s,b)
q=s.w
return(q===11||q===12?"("+r+")":r)+"?"}if(m===7)return"FutureOr<"+A.bl(a.x,b)+">"
if(m===8){p=A.vG(a.x)
o=a.y
return o.length>0?p+("<"+A.qY(o,b)+">"):p}if(m===10)return A.vr(a,b)
if(m===11)return A.qN(a,b,null)
if(m===12)return A.qN(a.x,b,a.y)
if(m===13){n=a.x
return b[b.length-1-n]}return"?"},
vG(a){var s=v.mangledGlobalNames[a]
if(s!=null)return s
return"minified:"+a},
uE(a,b){var s=a.tR[b]
while(typeof s=="string")s=a.tR[s]
return s},
uD(a,b){var s,r,q,p,o,n=a.eT,m=n[b]
if(m==null)return A.nV(a,b,!1)
else if(typeof m=="number"){s=m
r=A.fG(a,5,"#")
q=A.o_(s)
for(p=0;p<s;++p)q[p]=r
o=A.fF(a,b,q)
n[b]=o
return o}else return m},
uC(a,b){return A.qJ(a.tR,b)},
uB(a,b){return A.qJ(a.eT,b)},
nV(a,b,c){var s,r=a.eC,q=r.get(b)
if(q!=null)return q
s=A.qA(A.qy(a,null,b,!1))
r.set(b,s)
return s},
fH(a,b,c){var s,r,q=b.z
if(q==null)q=b.z=new Map()
s=q.get(c)
if(s!=null)return s
r=A.qA(A.qy(a,b,c,!0))
q.set(c,r)
return r},
qH(a,b,c){var s,r,q,p=b.Q
if(p==null)p=b.Q=new Map()
s=c.as
r=p.get(s)
if(r!=null)return r
q=A.pd(a,b,c.w===9?c.y:[c])
p.set(s,q)
return q},
cu(a,b){b.a=A.v4
b.b=A.v5
return b},
fG(a,b,c){var s,r,q=a.eC.get(c)
if(q!=null)return q
s=new A.bD(null,null)
s.w=b
s.as=c
r=A.cu(a,s)
a.eC.set(c,r)
return r},
qF(a,b,c){var s,r=b.as+"?",q=a.eC.get(r)
if(q!=null)return q
s=A.uz(a,b,r,c)
a.eC.set(r,s)
return s},
uz(a,b,c,d){var s,r,q
if(d){s=b.w
r=!0
if(!A.d5(b))if(!(b===t.P||b===t.v))if(s!==6)r=s===7&&A.e2(b.x)
if(r)return b
else if(s===1)return t.P}q=new A.bD(null,null)
q.w=6
q.x=b
q.as=c
return A.cu(a,q)},
qE(a,b,c){var s,r=b.as+"/",q=a.eC.get(r)
if(q!=null)return q
s=A.ux(a,b,r,c)
a.eC.set(r,s)
return s},
ux(a,b,c,d){var s,r
if(d){s=b.w
if(A.d5(b)||b===t.C)return b
else if(s===1)return A.fF(a,"b8",[b])
else if(b===t.P||b===t.v)return t.bG}r=new A.bD(null,null)
r.w=7
r.x=b
r.as=c
return A.cu(a,r)},
uA(a,b){var s,r,q=""+b+"^",p=a.eC.get(q)
if(p!=null)return p
s=new A.bD(null,null)
s.w=13
s.x=b
s.as=q
r=A.cu(a,s)
a.eC.set(q,r)
return r},
fE(a){var s,r,q,p=a.length
for(s="",r="",q=0;q<p;++q,r=",")s+=r+a[q].as
return s},
uw(a){var s,r,q,p,o,n=a.length
for(s="",r="",q=0;q<n;q+=3,r=","){p=a[q]
o=a[q+1]?"!":":"
s+=r+p+o+a[q+2].as}return s},
fF(a,b,c){var s,r,q,p=b
if(c.length>0)p+="<"+A.fE(c)+">"
s=a.eC.get(p)
if(s!=null)return s
r=new A.bD(null,null)
r.w=8
r.x=b
r.y=c
if(c.length>0)r.c=c[0]
r.as=p
q=A.cu(a,r)
a.eC.set(p,q)
return q},
pd(a,b,c){var s,r,q,p,o,n
if(b.w===9){s=b.x
r=b.y.concat(c)}else{r=c
s=b}q=s.as+(";<"+A.fE(r)+">")
p=a.eC.get(q)
if(p!=null)return p
o=new A.bD(null,null)
o.w=9
o.x=s
o.y=r
o.as=q
n=A.cu(a,o)
a.eC.set(q,n)
return n},
qG(a,b,c){var s,r,q="+"+(b+"("+A.fE(c)+")"),p=a.eC.get(q)
if(p!=null)return p
s=new A.bD(null,null)
s.w=10
s.x=b
s.y=c
s.as=q
r=A.cu(a,s)
a.eC.set(q,r)
return r},
qD(a,b,c){var s,r,q,p,o,n=b.as,m=c.a,l=m.length,k=c.b,j=k.length,i=c.c,h=i.length,g="("+A.fE(m)
if(j>0){s=l>0?",":""
g+=s+"["+A.fE(k)+"]"}if(h>0){s=l>0?",":""
g+=s+"{"+A.uw(i)+"}"}r=n+(g+")")
q=a.eC.get(r)
if(q!=null)return q
p=new A.bD(null,null)
p.w=11
p.x=b
p.y=c
p.as=r
o=A.cu(a,p)
a.eC.set(r,o)
return o},
pe(a,b,c,d){var s,r=b.as+("<"+A.fE(c)+">"),q=a.eC.get(r)
if(q!=null)return q
s=A.uy(a,b,c,r,d)
a.eC.set(r,s)
return s},
uy(a,b,c,d,e){var s,r,q,p,o,n,m,l
if(e){s=c.length
r=A.o_(s)
for(q=0,p=0;p<s;++p){o=c[p]
if(o.w===1){r[p]=o;++q}}if(q>0){n=A.d0(a,b,r,0)
m=A.dZ(a,c,r,0)
return A.pe(a,n,m,c!==m)}}l=new A.bD(null,null)
l.w=12
l.x=b
l.y=c
l.as=d
return A.cu(a,l)},
qy(a,b,c,d){return{u:a,e:b,r:c,s:[],p:0,n:d}},
qA(a){var s,r,q,p,o,n,m,l=a.r,k=a.s
for(s=l.length,r=0;r<s;){q=l.charCodeAt(r)
if(q>=48&&q<=57)r=A.uj(r+1,q,l,k)
else if((((q|32)>>>0)-97&65535)<26||q===95||q===36||q===124)r=A.qz(a,r,l,k,!1)
else if(q===46)r=A.qz(a,r,l,k,!0)
else{++r
switch(q){case 44:break
case 58:k.push(!1)
break
case 33:k.push(!0)
break
case 59:k.push(A.cY(a.u,a.e,k.pop()))
break
case 94:k.push(A.uA(a.u,k.pop()))
break
case 35:k.push(A.fG(a.u,5,"#"))
break
case 64:k.push(A.fG(a.u,2,"@"))
break
case 126:k.push(A.fG(a.u,3,"~"))
break
case 60:k.push(a.p)
a.p=k.length
break
case 62:A.ul(a,k)
break
case 38:A.uk(a,k)
break
case 63:p=a.u
k.push(A.qF(p,A.cY(p,a.e,k.pop()),a.n))
break
case 47:p=a.u
k.push(A.qE(p,A.cY(p,a.e,k.pop()),a.n))
break
case 40:k.push(-3)
k.push(a.p)
a.p=k.length
break
case 41:A.ui(a,k)
break
case 91:k.push(a.p)
a.p=k.length
break
case 93:o=k.splice(a.p)
A.qB(a.u,a.e,o)
a.p=k.pop()
k.push(o)
k.push(-1)
break
case 123:k.push(a.p)
a.p=k.length
break
case 125:o=k.splice(a.p)
A.un(a.u,a.e,o)
a.p=k.pop()
k.push(o)
k.push(-2)
break
case 43:n=l.indexOf("(",r)
k.push(l.substring(r,n))
k.push(-4)
k.push(a.p)
a.p=k.length
r=n+1
break
default:throw"Bad character "+q}}}m=k.pop()
return A.cY(a.u,a.e,m)},
uj(a,b,c,d){var s,r,q=b-48
for(s=c.length;a<s;++a){r=c.charCodeAt(a)
if(!(r>=48&&r<=57))break
q=q*10+(r-48)}d.push(q)
return a},
qz(a,b,c,d,e){var s,r,q,p,o,n,m=b+1
for(s=c.length;m<s;++m){r=c.charCodeAt(m)
if(r===46){if(e)break
e=!0}else{if(!((((r|32)>>>0)-97&65535)<26||r===95||r===36||r===124))q=r>=48&&r<=57
else q=!0
if(!q)break}}p=c.substring(b,m)
if(e){s=a.u
o=a.e
if(o.w===9)o=o.x
n=A.uE(s,o.x)[p]
if(n==null)A.al('No "'+p+'" in "'+A.tO(o)+'"')
d.push(A.fH(s,o,n))}else d.push(p)
return m},
ul(a,b){var s,r=a.u,q=A.qx(a,b),p=b.pop()
if(typeof p=="string")b.push(A.fF(r,p,q))
else{s=A.cY(r,a.e,p)
switch(s.w){case 11:b.push(A.pe(r,s,q,a.n))
break
default:b.push(A.pd(r,s,q))
break}}},
ui(a,b){var s,r,q,p=a.u,o=b.pop(),n=null,m=null
if(typeof o=="number")switch(o){case-1:n=b.pop()
break
case-2:m=b.pop()
break
default:b.push(o)
break}else b.push(o)
s=A.qx(a,b)
o=b.pop()
switch(o){case-3:o=b.pop()
if(n==null)n=p.sEA
if(m==null)m=p.sEA
r=A.cY(p,a.e,o)
q=new A.i4()
q.a=s
q.b=n
q.c=m
b.push(A.qD(p,r,q))
return
case-4:b.push(A.qG(p,b.pop(),s))
return
default:throw A.c(A.e5("Unexpected state under `()`: "+A.D(o)))}},
uk(a,b){var s=b.pop()
if(0===s){b.push(A.fG(a.u,1,"0&"))
return}if(1===s){b.push(A.fG(a.u,4,"1&"))
return}throw A.c(A.e5("Unexpected extended operation "+A.D(s)))},
qx(a,b){var s=b.splice(a.p)
A.qB(a.u,a.e,s)
a.p=b.pop()
return s},
cY(a,b,c){if(typeof c=="string")return A.fF(a,c,a.sEA)
else if(typeof c=="number"){b.toString
return A.um(a,b,c)}else return c},
qB(a,b,c){var s,r=c.length
for(s=0;s<r;++s)c[s]=A.cY(a,b,c[s])},
un(a,b,c){var s,r=c.length
for(s=2;s<r;s+=3)c[s]=A.cY(a,b,c[s])},
um(a,b,c){var s,r,q=b.w
if(q===9){if(c===0)return b.x
s=b.y
r=s.length
if(c<=r)return s[c-1]
c-=r
b=b.x
q=b.w}else if(c===0)return b
if(q!==8)throw A.c(A.e5("Indexed base must be an interface type"))
s=b.y
if(c<=s.length)return s[c-1]
throw A.c(A.e5("Bad index "+c+" for "+b.l(0)))},
wc(a,b,c){var s,r=b.d
if(r==null)r=b.d=new Map()
s=r.get(c)
if(s==null){s=A.aF(a,b,null,c,null)
r.set(c,s)}return s},
aF(a,b,c,d,e){var s,r,q,p,o,n,m,l,k,j,i
if(b===d)return!0
if(A.d5(d))return!0
s=b.w
if(s===4)return!0
if(A.d5(b))return!1
if(b.w===1)return!0
r=s===13
if(r)if(A.aF(a,c[b.x],c,d,e))return!0
q=d.w
p=t.P
if(b===p||b===t.v){if(q===7)return A.aF(a,b,c,d.x,e)
return d===p||d===t.v||q===6}if(d===t.C){if(s===7)return A.aF(a,b.x,c,d,e)
return s!==6}if(s===7){if(!A.aF(a,b.x,c,d,e))return!1
return A.aF(a,A.p2(a,b),c,d,e)}if(s===6)return A.aF(a,p,c,d,e)&&A.aF(a,b.x,c,d,e)
if(q===7){if(A.aF(a,b,c,d.x,e))return!0
return A.aF(a,b,c,A.p2(a,d),e)}if(q===6)return A.aF(a,b,c,p,e)||A.aF(a,b,c,d.x,e)
if(r)return!1
p=s!==11
if((!p||s===12)&&d===t.b8)return!0
o=s===10
if(o&&d===t.gT)return!0
if(q===12){if(b===t.g)return!0
if(s!==12)return!1
n=b.y
m=d.y
l=n.length
if(l!==m.length)return!1
c=c==null?n:n.concat(c)
e=e==null?m:m.concat(e)
for(k=0;k<l;++k){j=n[k]
i=m[k]
if(!A.aF(a,j,c,i,e)||!A.aF(a,i,e,j,c))return!1}return A.qP(a,b.x,c,d.x,e)}if(q===11){if(b===t.g)return!0
if(p)return!1
return A.qP(a,b,c,d,e)}if(s===8){if(q!==8)return!1
return A.vb(a,b,c,d,e)}if(o&&q===10)return A.vg(a,b,c,d,e)
return!1},
qP(a3,a4,a5,a6,a7){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2
if(!A.aF(a3,a4.x,a5,a6.x,a7))return!1
s=a4.y
r=a6.y
q=s.a
p=r.a
o=q.length
n=p.length
if(o>n)return!1
m=n-o
l=s.b
k=r.b
j=l.length
i=k.length
if(o+j<n+i)return!1
for(h=0;h<o;++h){g=q[h]
if(!A.aF(a3,p[h],a7,g,a5))return!1}for(h=0;h<m;++h){g=l[h]
if(!A.aF(a3,p[o+h],a7,g,a5))return!1}for(h=0;h<i;++h){g=l[m+h]
if(!A.aF(a3,k[h],a7,g,a5))return!1}f=s.c
e=r.c
d=f.length
c=e.length
for(b=0,a=0;a<c;a+=3){a0=e[a]
for(;;){if(b>=d)return!1
a1=f[b]
b+=3
if(a0<a1)return!1
a2=f[b-2]
if(a1<a0){if(a2)return!1
continue}g=e[a+1]
if(a2&&!g)return!1
g=f[b-1]
if(!A.aF(a3,e[a+2],a7,g,a5))return!1
break}}while(b<d){if(f[b+1])return!1
b+=3}return!0},
vb(a,b,c,d,e){var s,r,q,p,o,n=b.x,m=d.x
while(n!==m){s=a.tR[n]
if(s==null)return!1
if(typeof s=="string"){n=s
continue}r=s[m]
if(r==null)return!1
q=r.length
p=q>0?new Array(q):v.typeUniverse.sEA
for(o=0;o<q;++o)p[o]=A.fH(a,b,r[o])
return A.qK(a,p,null,c,d.y,e)}return A.qK(a,b.y,null,c,d.y,e)},
qK(a,b,c,d,e,f){var s,r=b.length
for(s=0;s<r;++s)if(!A.aF(a,b[s],d,e[s],f))return!1
return!0},
vg(a,b,c,d,e){var s,r=b.y,q=d.y,p=r.length
if(p!==q.length)return!1
if(b.x!==d.x)return!1
for(s=0;s<p;++s)if(!A.aF(a,r[s],c,q[s],e))return!1
return!0},
e2(a){var s=a.w,r=!0
if(!(a===t.P||a===t.v))if(!A.d5(a))if(s!==6)r=s===7&&A.e2(a.x)
return r},
d5(a){var s=a.w
return s===2||s===3||s===4||s===5||a===t.X},
qJ(a,b){var s,r,q=Object.keys(b),p=q.length
for(s=0;s<p;++s){r=q[s]
a[r]=b[r]}},
o_(a){return a>0?new Array(a):v.typeUniverse.sEA},
bD:function bD(a,b){var _=this
_.a=a
_.b=b
_.r=_.f=_.d=_.c=null
_.w=0
_.as=_.Q=_.z=_.y=_.x=null},
i4:function i4(){this.c=this.b=this.a=null},
nU:function nU(a){this.a=a},
i3:function i3(){},
fD:function fD(a){this.a=a},
tZ(){var s,r,q
if(self.scheduleImmediate!=null)return A.vJ()
if(self.MutationObserver!=null&&self.document!=null){s={}
r=self.document.createElement("div")
q=self.document.createElement("span")
s.a=null
new self.MutationObserver(A.fN(new A.nj(s),1)).observe(r,{childList:true})
return new A.ni(s,r,q)}else if(self.setImmediate!=null)return A.vK()
return A.vL()},
u_(a){self.scheduleImmediate(A.fN(new A.nk(a),0))},
u0(a){self.setImmediate(A.fN(new A.nl(a),0))},
u1(a){A.qq(B.f,a)},
qq(a,b){var s=B.c.a3(a.a,1000)
return A.uu(s<0?0:s,b)},
uu(a,b){var s=new A.ih()
s.fU(a,b)
return s},
uv(a,b){var s=new A.ih()
s.fV(a,b)
return s},
b6(a){return new A.hX(new A.ad($.V,a.i("ad<0>")),a.i("hX<0>"))},
b5(a,b){a.$2(0,null)
b.b=!0
return b.a},
ar(a,b){A.uT(a,b)},
b4(a,b){b.fc(a)},
b3(a,b){b.fd(A.aV(a),A.bN(a))},
uT(a,b){var s,r,q=new A.o0(b),p=new A.o1(b)
if(a instanceof A.ad)a.f1(q,p,t.z)
else{s=t.z
if(a instanceof A.ad)a.cH(q,p,s)
else{r=new A.ad($.V,t.eI)
r.a=8
r.c=a
r.f1(q,p,s)}}},
b7(a){var s=function(b,c){return function(d,e){while(true){try{b(d,e)
break}catch(r){e=r
d=c}}}}(a,1)
return $.V.dK(new A.oc(s),t.H,t.S,t.z)},
qC(a,b,c){return 0},
iu(a){var s
if(t.Q.b(a)){s=a.gbH()
if(s!=null)return s}return B.au},
th(a,b){var s=new A.ad($.V,b.i("ad<0>"))
A.wl(new A.jd(a,s))
return s},
ti(a,b){var s,r,q,p,o,n,m,l,k,j,i,h={},g=null,f=!1,e=new A.ad($.V,b.i("ad<t<0>>"))
h.a=null
h.b=0
h.c=h.d=null
s=new A.jf(h,g,f,e)
try{for(n=a.length,m=t.P,l=0,k=0;l<a.length;a.length===n||(0,A.n)(a),++l){r=a[l]
q=k
r.cH(new A.je(h,q,e,b,g,f),s,m)
k=++h.b}if(k===0){n=e
n.ca(A.a([],b.i("C<0>")))
return n}h.a=A.a9(k,null,!1,b.i("0?"))}catch(j){p=A.aV(j)
o=A.bN(j)
if(h.b===0||f){n=e
m=p
k=o
i=A.pk(m,k)
if(i==null)m=new A.aK(m,k==null?A.iu(m):k)
else m=i
n.c7(m)
return n}else{h.d=p
h.c=o}}return e},
pk(a,b){var s,r,q,p=$.V
if(p===B.m)return null
s=p.fh(a,b)
if(s==null)return null
r=s.a
q=s.b
if(t.Q.b(r))A.p0(r,q)
return s},
v7(a,b){var s
if($.V!==B.m){s=A.pk(a,b)
if(s!=null)return s}if(b==null)if(t.Q.b(a)){b=a.gbH()
if(b==null){A.p0(a,B.au)
b=B.au}}else b=B.au
else if(t.Q.b(a))A.p0(a,b)
return new A.aK(a,b)},
nx(a,b,c){var s,r,q,p={},o=p.a=a
while(s=o.a,(s&4)!==0){o=o.c
p.a=o}if(o===b){s=A.tR()
b.c7(new A.aK(new A.bz(!0,o,null,"Cannot complete a future with itself"),s))
return}r=b.a&1
s=o.a=s|r
if((s&24)===0){q=b.c
b.a=b.a&1|4
b.c=o
o.eM(q)
return}if(!c)if(b.c==null)o=(s&16)===0||r!==0
else o=!1
else o=!0
if(o){q=b.bU()
b.c8(p.a)
A.cT(b,q)
return}b.a^=2
b.b.bi(new A.ny(p,b))},
cT(a,b){var s,r,q,p,o,n,m,l,k,j,i,h,g={},f=g.a=a
for(;;){s={}
r=f.a
q=(r&16)===0
p=!q
if(b==null){if(p&&(r&1)===0){r=f.c
f.b.dA(r.a,r.b)}return}s.a=b
o=b.a
for(f=b;o!=null;f=o,o=n){f.a=null
A.cT(g.a,f)
s.a=o
n=o.a}r=g.a
m=r.c
s.b=p
s.c=m
if(q){l=f.c
l=(l&1)!==0||(l&15)===8}else l=!0
if(l){k=f.b.b
if(p){f=r.b
f=!(f===k||f.gb3()===k.gb3())}else f=!1
if(f){f=g.a
r=f.c
f.b.dA(r.a,r.b)
return}j=$.V
if(j!==k)$.V=k
else j=null
f=s.a.c
if((f&15)===8)new A.nC(s,g,p).$0()
else if(q){if((f&1)!==0)new A.nB(s,m).$0()}else if((f&2)!==0)new A.nA(g,s).$0()
if(j!=null)$.V=j
f=s.c
if(f instanceof A.ad){r=s.a.$ti
r=r.i("b8<2>").b(f)||!r.y[1].b(f)}else r=!1
if(r){i=s.a.b
if((f.a&24)!==0){h=i.c
i.c=null
b=i.cg(h)
i.a=f.a&30|i.a&1
i.c=f.c
g.a=f
continue}else A.nx(f,i,!0)
return}}i=s.a.b
h=i.c
i.c=null
b=i.cg(h)
f=s.b
r=s.c
if(!f){i.a=8
i.c=r}else{i.a=i.a&1|16
i.c=r}g.a=i
f=i}},
vs(a,b){if(t.ag.b(a))return b.dK(a,t.z,t.C,t.l)
if(t.bI.b(a))return b.cG(a,t.z,t.C)
throw A.c(A.oC(a,"onError",u.c))},
vm(){var s,r
for(s=$.dY;s!=null;s=$.dY){$.fL=null
r=s.b
$.dY=r
if(r==null)$.fK=null
s.a.$0()}},
vD(){$.pl=!0
try{A.vm()}finally{$.fL=null
$.pl=!1
if($.dY!=null)$.pA().$1(A.r1())}},
qZ(a){var s=new A.hY(a),r=$.fK
if(r==null){$.dY=$.fK=s
if(!$.pl)$.pA().$1(A.r1())}else $.fK=r.b=s},
vA(a){var s,r,q,p=$.dY
if(p==null){A.qZ(a)
$.fL=$.fK
return}s=new A.hY(a)
r=$.fL
if(r==null){s.b=p
$.dY=$.fL=s}else{q=r.b
s.b=q
$.fL=r.b=s
if(q==null)$.fK=s}},
wl(a){var s,r=null,q=$.V
if(B.m===q){A.o8(r,r,B.m,a)
return}if(B.m===q.gdm().a)s=B.m.gb3()===q.gb3()
else s=!1
if(s){A.o8(r,r,q,q.cF(a,t.H))
return}s=$.V
s.bi(s.dt(a))},
wK(a){A.cv(a,"stream",t.C)
return new A.ic()},
wk(a,b,c){return A.vz(a,b,null,c)},
vz(a,b,c,d){return $.V.fk(c,b).bF(a,d)},
vw(a,b,c,d,e){A.o5(d,e)},
o5(a,b){A.vA(new A.o6(a,b))},
o7(a,b,c,d){var s,r=$.V
if(r===c)return d.$0()
$.V=c
s=r
try{r=d.$0()
return r}finally{$.V=s}},
pp(a,b,c,d,e){var s,r=$.V
if(r===c)return d.$1(e)
$.V=c
s=r
try{r=d.$1(e)
return r}finally{$.V=s}},
po(a,b,c,d,e,f){var s,r=$.V
if(r===c)return d.$2(e,f)
$.V=c
s=r
try{r=d.$2(e,f)
return r}finally{$.V=s}},
qW(a,b,c,d){return d},
qX(a,b,c,d){return d},
qV(a,b,c,d){return d},
vv(a,b,c,d,e){return null},
o8(a,b,c,d){var s,r
if(B.m!==c){s=B.m.gb3()
r=c.gb3()
d=s!==r?c.dt(d):c.ds(d,t.H)}A.qZ(d)},
vu(a,b,c,d,e){return A.qq(d,B.m!==c?c.ds(e,t.H):e)},
vt(a,b,c,d,e){var s
if(B.m!==c)e=c.fb(e,t.H,t.dn)
s=B.c.a3(d.a,1000)
return A.uv(s<0?0:s,e)},
vx(a,b,c,d){A.pw(d)},
vq(a){$.V.fq(a)},
qU(a,b,c,d,e){var s,r,q
$.qT=A.vM()
if(d==null)d=B.dm
if(e==null)s=c.geA()
else{r=t.X
s=A.tj(e,r,r)}r=new A.i0(c.geU(),c.geW(),c.geV(),c.geR(),c.geS(),c.geQ(),c.gee(),c.gdm(),c.ge9(),c.ge8(),c.geN(),c.gen(),c.gd5(),c,s)
q=d.a
if(q!=null)r.as=new A.aU(r,q)
return r},
nj:function nj(a){this.a=a},
ni:function ni(a,b,c){this.a=a
this.b=b
this.c=c},
nk:function nk(a){this.a=a},
nl:function nl(a){this.a=a},
ih:function ih(){this.c=0},
nT:function nT(a,b){this.a=a
this.b=b},
nS:function nS(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
hX:function hX(a,b){this.a=a
this.b=!1
this.$ti=b},
o0:function o0(a){this.a=a},
o1:function o1(a){this.a=a},
oc:function oc(a){this.a=a},
c8:function c8(a,b){var _=this
_.a=a
_.e=_.d=_.c=_.b=null
_.$ti=b},
ct:function ct(a,b){this.a=a
this.$ti=b},
aK:function aK(a,b){this.a=a
this.b=b},
fp:function fp(){},
fn:function fn(a,b){var _=this
_.b=a
_.c=0
_.e=_.d=null
_.$ti=b},
jd:function jd(a,b){this.a=a
this.b=b},
jf:function jf(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
je:function je(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f},
hZ:function hZ(){},
fo:function fo(a,b){this.a=a
this.$ti=b},
dV:function dV(a,b,c,d,e){var _=this
_.a=null
_.b=a
_.c=b
_.d=c
_.e=d
_.$ti=e},
ad:function ad(a,b){var _=this
_.a=0
_.b=a
_.c=null
_.$ti=b},
nu:function nu(a,b){this.a=a
this.b=b},
nz:function nz(a,b){this.a=a
this.b=b},
ny:function ny(a,b){this.a=a
this.b=b},
nw:function nw(a,b){this.a=a
this.b=b},
nv:function nv(a,b){this.a=a
this.b=b},
nC:function nC(a,b,c){this.a=a
this.b=b
this.c=c},
nD:function nD(a,b){this.a=a
this.b=b},
nE:function nE(a){this.a=a},
nB:function nB(a,b){this.a=a
this.b=b},
nA:function nA(a,b){this.a=a
this.b=b},
hY:function hY(a){this.a=a
this.b=null},
i2:function i2(){},
i1:function i1(){},
ic:function ic(){},
aU:function aU(a,b){this.a=a
this.b=b},
ii:function ii(){},
i0:function i0(a,b,c,d,e,f,g,h,i,j,k,l,m,n,o){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g
_.w=h
_.x=i
_.y=j
_.z=k
_.Q=l
_.as=m
_.at=null
_.ax=n
_.ay=o},
np:function np(a,b,c){this.a=a
this.b=b
this.c=c},
nq:function nq(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
no:function no(a,b){this.a=a
this.b=b},
ib:function ib(){},
nQ:function nQ(a,b,c){this.a=a
this.b=b
this.c=c},
nR:function nR(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
nP:function nP(a,b){this.a=a
this.b=b},
dX:function dX(a){this.a=a},
o6:function o6(a,b){this.a=a
this.b=b},
ij:function ij(a,b,c,d,e,f,g,h,i,j,k,l,m){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g
_.w=h
_.x=i
_.y=j
_.z=k
_.Q=l
_.as=m},
pW(a,b){return new A.fs(a.i("@<0>").ar(b).i("fs<1,2>"))},
p9(a,b){var s=a[b]
return s===a?null:s},
pb(a,b,c){if(c==null)a[b]=a
else a[b]=c},
pa(){var s=Object.create(null)
A.pb(s,"<non-identifier-key>",s)
delete s["<non-identifier-key>"]
return s},
c0(a,b){return new A.bZ(a.i("@<0>").ar(b).i("bZ<1,2>"))},
a7(a,b,c){return A.w6(a,new A.bZ(b.i("@<0>").ar(c).i("bZ<1,2>")))},
o(a,b){return new A.bZ(a.i("@<0>").ar(b).i("bZ<1,2>"))},
oW(a){return new A.cX(a.i("cX<0>"))},
aD(a){return new A.cX(a.i("cX<0>"))},
pc(){var s=Object.create(null)
s["<non-identifier-key>"]=s
delete s["<non-identifier-key>"]
return s},
i7(a,b,c){var s=new A.c7(a,b,c.i("c7<0>"))
s.c=a.e
return s},
tj(a,b,c){var s=A.pW(b,c)
a.a0(0,new A.jr(s,b,c))
return s},
Z(a,b,c){var s=A.c0(b,c)
a.a0(0,new A.lS(s,b,c))
return s},
q6(a,b,c){var s=A.c0(b,c)
s.X(0,a)
return s},
tw(a,b){var s,r=A.oW(b)
for(s=J.as(a);s.p();)r.T(0,b.a(s.gD()))
return r},
q7(a,b){var s=A.oW(b)
s.X(0,a)
return s},
oX(a){var s,r
if(A.pu(a))return"{...}"
s=new A.cn("")
try{r={}
$.d1.push(a)
s.a+="{"
r.a=!0
a.a0(0,new A.lU(r,s))
s.a+="}"}finally{$.d1.pop()}r=s.a
return r.charCodeAt(0)==0?r:r},
fs:function fs(a){var _=this
_.a=0
_.e=_.d=_.c=_.b=null
_.$ti=a},
nF:function nF(a){this.a=a},
cU:function cU(a,b){this.a=a
this.$ti=b},
ft:function ft(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.d=null
_.$ti=c},
cX:function cX(a){var _=this
_.a=0
_.f=_.e=_.d=_.c=_.b=null
_.r=0
_.$ti=a},
nM:function nM(a){this.a=a
this.c=this.b=null},
c7:function c7(a,b,c){var _=this
_.a=a
_.b=b
_.d=_.c=null
_.$ti=c},
jr:function jr(a,b,c){this.a=a
this.b=b
this.c=c},
lS:function lS(a,b,c){this.a=a
this.b=b
this.c=c},
a3:function a3(){},
aa:function aa(){},
lT:function lT(a){this.a=a},
lU:function lU(a,b){this.a=a
this.b=b},
fu:function fu(a,b){this.a=a
this.$ti=b},
fv:function fv(a,b,c){var _=this
_.a=a
_.b=b
_.c=null
_.$ti=c},
cl:function cl(){},
fB:function fB(){},
vo(a,b){var s,r,q,p=null
try{p=JSON.parse(a)}catch(r){s=A.aV(r)
q=A.cf(String(s),null,null)
throw A.c(q)}q=A.o2(p)
return q},
o2(a){var s
if(a==null)return null
if(typeof a!="object")return a
if(!Array.isArray(a))return new A.i5(a,Object.create(null))
for(s=0;s<a.length;++s)a[s]=A.o2(a[s])
return a},
uG(a,b,c){var s,r,q,p=c-b
if(p<=4096)s=$.rE()
else s=new Uint8Array(p)
for(r=0;r<p;++r){q=a[b+r]
if((q&255)!==q)q=255
s[r]=q}return s},
uF(a,b,c,d){var s=a?$.rD():$.rC()
if(s==null)return null
if(0===c&&d===b.length)return A.qI(s,b)
return A.qI(s,b.subarray(c,d))},
qI(a,b){var s,r
try{s=a.decode(b)
return s}catch(r){}return null},
q4(a,b,c){return new A.eC(a,b)},
uX(a){return a.am()},
uf(a,b){return new A.nJ(a,[],A.w1())},
ug(a,b,c){var s,r=new A.cn(""),q=A.uf(r,b)
q.cJ(a)
s=r.a
return s.charCodeAt(0)==0?s:s},
uH(a){switch(a){case 65:return"Missing extension byte"
case 67:return"Unexpected extension byte"
case 69:return"Invalid UTF-8 byte"
case 71:return"Overlong encoding"
case 73:return"Out of unicode range"
case 75:return"Encoded surrogate"
case 77:return"Unfinished UTF-8 octet sequence"
default:return""}},
i5:function i5(a,b){this.a=a
this.b=b
this.c=null},
nI:function nI(a){this.a=a},
i6:function i6(a){this.a=a},
nY:function nY(){},
nX:function nX(){},
fW:function fW(){},
fZ:function fZ(){},
iZ:function iZ(){},
eC:function eC(a,b){this.a=a
this.b=b},
hm:function hm(a,b){this.a=a
this.b=b},
lO:function lO(){},
lQ:function lQ(a){this.b=a},
lP:function lP(a){this.a=a},
nK:function nK(){},
nL:function nL(a,b){this.a=a
this.b=b},
nJ:function nJ(a,b,c){this.c=a
this.a=b
this.b=c},
nc:function nc(){},
nd:function nd(){},
nZ:function nZ(a){this.b=0
this.c=a},
hR:function hR(a){this.a=a},
cZ:function cZ(a){this.a=a
this.b=16
this.c=0},
d4(a){var s=A.a4(a,null)
if(s!=null)return s
throw A.c(A.cf(a,null,null))},
cw(a){var s=A.aH(a)
if(s!=null)return s
throw A.c(A.cf("Invalid double",a,null))},
t8(a,b){a=A.aC(a,new Error())
a.stack=b.l(0)
throw a},
a9(a,b,c,d){var s,r=c?J.oR(a,d):J.q1(a,d)
if(a!==0&&b!=null)for(s=0;s<r.length;++s)r[s]=b
return r},
a6(a,b,c){var s,r=A.a([],c.i("C<0>"))
for(s=J.as(a);s.p();)r.push(s.gD())
if(b)return r
r.$flags=1
return r},
r(a,b){var s,r
if(Array.isArray(a))return A.a(a.slice(0),b.i("C<0>"))
s=A.a([],b.i("C<0>"))
for(r=J.as(a);r.p();)s.push(r.gD())
return s},
q8(a,b){var s=A.a6(a,!1,b)
s.$flags=3
return s},
tS(a,b,c){var s,r
A.eU(b,"start")
s=c-b
if(s<0)throw A.c(A.ax(c,b,null,"end",null))
if(s===0)return""
r=A.tT(a,b,c)
return r},
tT(a,b,c){var s=a.length
if(b>=s)return""
return A.tG(a,b,c==null||c>s?s:c)},
aI(a,b){return new A.dw(a,A.oS(a,!1,b,!1,!1,""))},
p5(a,b,c){var s=J.as(b)
if(!s.p())return a
if(c.length===0){do a+=A.D(s.gD())
while(s.p())}else{a+=A.D(s.gD())
while(s.p())a=a+c+A.D(s.gD())}return a},
tR(){return A.bN(new Error())},
t4(a,b,c,d,e,f,g,h,i){var s=A.tH(a,b,c,d,e,f,g,h,i)
if(s==null)return null
return new A.aw(A.oF(s,h,i),h,i)},
t6(a){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c=$.rm().bq(a)
if(c!=null){s=new A.iS()
r=c.b
q=r[1]
q.toString
p=A.d4(q)
q=r[2]
q.toString
o=A.d4(q)
q=r[3]
q.toString
n=A.d4(q)
m=s.$1(r[4])
l=s.$1(r[5])
k=s.$1(r[6])
j=new A.iT().$1(r[7])
i=B.c.a3(j,1000)
h=r[8]!=null
if(h){g=r[9]
if(g!=null){f=g==="-"?-1:1
q=r[10]
q.toString
e=A.d4(q)
l-=f*(s.$1(r[11])+60*e)}}d=A.t4(p,o,n,m,l,k,i,j%1000,h)
if(d==null)throw A.c(A.cf("Time out of range",a,null))
return d}else throw A.c(A.cf("Invalid date format",a,null))},
bA(a){var s,r
try{s=A.t6(a)
return s}catch(r){if(A.aV(r) instanceof A.h8)return null
else throw r}},
oF(a,b,c){var s="microsecond"
if(b<0||b>999)throw A.c(A.ax(b,0,999,s,null))
if(a<-864e13||a>864e13)throw A.c(A.ax(a,-864e13,864e13,"millisecondsSinceEpoch",null))
if(a===864e13&&b!==0)throw A.c(A.oC(b,s,"Time including microseconds is outside valid range"))
A.cv(c,"isUtc",t.y)
return a},
pQ(a){var s=Math.abs(a),r=a<0?"-":""
if(s>=1000)return""+a
if(s>=100)return r+"0"+s
if(s>=10)return r+"00"+s
return r+"000"+s},
t5(a){var s=Math.abs(a),r=a<0?"-":"+"
if(s>=1e5)return r+s
return r+"0"+s},
iR(a){if(a>=100)return""+a
if(a>=10)return"0"+a
return"00"+a},
bS(a){if(a>=10)return""+a
return"0"+a},
iY(a,b){return new A.bU(b+864e8*a)},
h4(a){if(typeof a=="number"||A.fI(a)||a==null)return J.x(a)
if(typeof a=="string")return JSON.stringify(a)
return A.qg(a)},
t9(a,b){A.cv(a,"error",t.C)
A.cv(b,"stackTrace",t.l)
A.t8(a,b)},
e5(a){return new A.fS(a)},
bn(a,b){return new A.bz(!1,null,b,a)},
oC(a,b,c){return new A.bz(!0,a,b,c)},
qi(a){var s=null
return new A.dL(s,s,!1,s,s,a)},
mH(a,b){return new A.dL(null,null,!0,a,b,"Value not in range")},
ax(a,b,c,d,e){return new A.dL(b,c,!0,a,d,"Invalid value")},
tK(a,b,c,d){if(a<b||a>c)throw A.c(A.ax(a,b,c,d,null))
return a},
c2(a,b,c){if(0>a||a>c)throw A.c(A.ax(a,0,c,"start",null))
if(b!=null){if(a>b||b>c)throw A.c(A.ax(b,a,c,"end",null))
return b}return c},
eU(a,b){if(a<0)throw A.c(A.ax(a,0,null,b,null))
return a},
oP(a,b,c,d){return new A.hd(b,!0,a,d,"Index out of range")},
a_(a){return new A.fi(a)},
qt(a){return new A.hN(a)},
fb(a){return new A.cm(a)},
aA(a){return new A.fY(a)},
q(a){return new A.ns(a)},
cf(a,b,c){return new A.h8(a,b,c)},
tp(a,b,c){var s,r
if(A.pu(a)){if(b==="("&&c===")")return"(...)"
return b+"..."+c}s=A.a([],t.s)
$.d1.push(a)
try{A.vk(a,s)}finally{$.d1.pop()}r=A.p5(b,s,", ")+c
return r.charCodeAt(0)==0?r:r},
oQ(a,b,c){var s,r
if(A.pu(a))return b+"..."+c
s=new A.cn(b)
$.d1.push(a)
try{r=s
r.a=A.p5(r.a,a,", ")}finally{$.d1.pop()}s.a+=c
r=s.a
return r.charCodeAt(0)==0?r:r},
vk(a,b){var s,r,q,p,o,n,m,l=a.gJ(a),k=0,j=0
for(;;){if(!(k<80||j<3))break
if(!l.p())return
s=A.D(l.gD())
b.push(s)
k+=s.length+2;++j}if(!l.p()){if(j<=5)return
r=b.pop()
q=b.pop()}else{p=l.gD();++j
if(!l.p()){if(j<=4){b.push(A.D(p))
return}r=A.D(p)
q=b.pop()
k+=r.length+2}else{o=l.gD();++j
for(;l.p();p=o,o=n){n=l.gD();++j
if(j>100){for(;;){if(!(k>75&&j>3))break
k-=b.pop().length+2;--j}b.push("...")
return}}q=A.D(p)
r=A.D(o)
k+=r.length+q.length+4}}if(j>b.length+2){k+=5
m="..."}else m=null
for(;;){if(!(k>80&&b.length>3))break
k-=b.pop().length+2
if(m==null){k+=5
m="..."}}if(m!=null)b.push(m)
b.push(q)
b.push(r)},
wg(a){var s=A.re(a)
if(s!=null)return s
throw A.c(A.cf(a,null,null))},
re(a){var s=B.a.V(a),r=A.a4(s,null)
return r==null?A.aH(s):r},
q9(a,b,c,d){var s
if(B.V===c){s=B.c.gY(a)
b=J.by(b)
return A.p7(A.cp(A.cp($.ow(),s),b))}if(B.V===d){s=B.c.gY(a)
b=J.by(b)
c=J.by(c)
return A.p7(A.cp(A.cp(A.cp($.ow(),s),b),c))}s=B.c.gY(a)
b=J.by(b)
c=J.by(c)
d=J.by(d)
d=A.p7(A.cp(A.cp(A.cp(A.cp($.ow(),s),b),c),d))
return d},
wh(a){var s=$.qT
if(s==null)A.pw(a)
else s.$1(a)},
aw:function aw(a,b,c){this.a=a
this.b=b
this.c=c},
iS:function iS(){},
iT:function iT(){},
bU:function bU(a){this.a=a},
nr:function nr(){},
ah:function ah(){},
fS:function fS(a){this.a=a},
c5:function c5(){},
bz:function bz(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
dL:function dL(a,b,c,d,e,f){var _=this
_.e=a
_.f=b
_.a=c
_.b=d
_.c=e
_.d=f},
hd:function hd(a,b,c,d,e){var _=this
_.f=a
_.a=b
_.b=c
_.c=d
_.d=e},
fi:function fi(a){this.a=a},
hN:function hN(a){this.a=a},
cm:function cm(a){this.a=a},
fY:function fY(a){this.a=a},
ht:function ht(){},
fa:function fa(){},
ns:function ns(a){this.a=a},
h8:function h8(a,b,c){this.a=a
this.b=b
this.c=c},
F:function F(){},
aj:function aj(a,b,c){this.a=a
this.b=b
this.$ti=c},
aE:function aE(){},
A:function A(){},
ig:function ig(a){this.a=a},
fc:function fc(){this.b=this.a=0},
cn:function cn(a){this.a=a},
u3(a,b){throw A.c(A.a_("Directory._createTemp"))},
u7(a){throw A.c(A.a_("Directory._systemTemp"))},
u5(a,b){throw A.c(A.a_("Directory._exists"))},
u2(a,b){throw A.c(A.a_("Directory._create"))},
u4(a,b,c){throw A.c(A.a_("Directory._deleteNative"))},
u6(a,b,c,d,e){throw A.c(A.a_("Directory._fillWithDirectoryListing"))},
ub(a,b){throw A.c(A.a_("File._exists"))},
u8(a,b,c){throw A.c(A.a_("File._create"))},
u9(a,b){throw A.c(A.a_("File._deleteNative"))},
ue(a,b,c){throw A.c(A.a_("File._rename"))},
ud(a,b,c){throw A.c(A.a_("File._open"))},
bL(){throw A.c(A.a_("_Namespace"))},
uh(){throw A.c(A.a_("_Namespace"))},
uo(){throw A.c(A.a_("Platform._numberOfProcessors"))},
uq(){throw A.c(A.a_("Platform._pathSeparator"))},
up(){throw A.c(A.a_("Platform._operatingSystem"))},
tJ(){throw A.c(A.a_("ProcessInfo.currentRss"))},
uW(a,b,c){var s
if(t.j.b(a)&&!J.az(J.Y(a,0),0)){s=J.X(a)
switch(s.h(a,0)){case 1:throw A.c(A.bn(b+": "+c,null))
case 2:throw A.c(A.tb(new A.m_(A.il(s.h(a,2)),A.qL(s.h(a,1))),b,c))
case 3:throw A.c(A.oJ("File closed",c,null))
default:throw A.c(A.e5("Unknown error"))}}},
dl(a){var s
A.oO()
s=A.oH(B.x.aB(a))
return new A.fq(a,s)},
t7(){A.oO()
var s=A.dl(A.u7(A.bL()))
return s},
h6(a){var s
A.oO()
s=A.oH(B.x.aB(a))
return new A.fr(a,s)},
oJ(a,b,c){return new A.dp(a,b,c)},
tb(a,b,c){if($.fO())switch(a.b){case 5:case 16:case 19:case 24:case 32:case 33:case 65:case 108:return new A.hy(b,c,a)
case 80:case 183:return new A.hz(b,c,a)
case 2:case 3:case 15:case 123:case 18:case 53:case 67:case 161:case 206:return new A.hA(b,c,a)
default:return new A.dp(b,c,a)}else switch(a.b){case 1:case 13:return new A.hy(b,c,a)
case 17:return new A.hz(b,c,a)
case 2:return new A.hA(b,c,a)
default:return new A.dp(b,c,a)}},
uc(){return A.uh()},
ua(a,b){b[0]=A.uc()},
oH(a){var s,r,q=a.length
if(q!==0)s=B.j.gW(a)!==0
else s=!0
if(s){r=new Uint8Array(q+1)
B.j.a8(r,0,q,a)
return r}else return a},
oI(a){var s,r
if($.fO())if(B.a.U(a,$.rn())){s=B.a.fl(a,A.aI("[/\\\\]",!0),2)
if(s===-1)return a}else s=B.a.U(a,"\\")||B.a.U(a,"/")?0:-1
else s=B.a.U(a,"/")?0:-1
r=B.a.iR(a,$.ro())
if(r>s)return B.a.O(a,0,r+1)
else if(s>-1)return B.a.O(a,0,s+1)
else return"."},
ta(a){var s
if(a.length===0)a="."
if($.fO())for(;;){s=$.ot()
if(!(!B.a.B(a,s)&&!B.a.B(a,"/")))break
a+=A.D(s)}else while(s=$.ot(),!B.a.B(a,s))a+=A.D(s)
return a},
oO(){var s=$.V.h(0,$.rF())
return s==null?null:s},
ur(){return A.uo()},
ut(){return A.uq()},
us(){return A.up()},
m_:function m_(a,b){this.a=a
this.b=b},
fq:function fq(a,b){this.a=a
this.b=b},
cD:function cD(a){this.a=a},
dp:function dp(a,b,c){this.a=a
this.b=b
this.c=c},
hy:function hy(a,b,c){this.a=a
this.b=b
this.c=c},
hz:function hz(a,b,c){this.a=a
this.b=b
this.c=c},
hA:function hA(a,b,c){this.a=a
this.b=b
this.c=c},
fr:function fr(a,b){this.a=a
this.b=b},
nt:function nt(a){this.a=a},
dn:function dn(){},
tg(a){var s,r=v.G.Promise,q=new A.jc(a)
if(typeof q=="function")A.al(A.bn("Attempting to rewrap a JS function.",null))
s=function(b,c){return function(d,e){return b(c,d,e,arguments.length)}}(A.uV,q)
s[$.os()]=q
return new r(s)},
jc:function jc(a){this.a=a},
ja:function ja(a){this.a=a},
jb:function jb(a){this.a=a},
nG:function nG(){},
i8:function i8(){this.b=this.a=0},
at(a,b,c){var s=a.BYTES_PER_ELEMENT
c=A.c2(b,c,B.c.b_(a.byteLength,s))
return J.rO(B.j.gai(a),a.byteOffset+b*s,(c-b)*s)},
pX(a,b,c){var s=a.BYTES_PER_ELEMENT,r=(A.c2(b,c,B.c.b_(a.byteLength,s))-b)*s
if(B.c.a7(r,4)!==0)throw A.c(A.bn("The number of bytes to view must be a multiple of 4",null))
return J.rQ(B.E.gai(a),a.byteOffset+b*s,B.c.a3(r,4))},
pU(a,b,c){var s=a.BYTES_PER_ELEMENT,r=(A.c2(b,c,B.c.b_(a.byteLength,s))-b)*s
if(B.c.a7(r,8)!==0)throw A.c(A.bn("The number of bytes to view must be a multiple of 8",null))
return J.rP(B.ab.gai(a),a.byteOffset+b*s,B.c.a3(r,8))},
j_:function j_(){},
pJ(a){var s,r,q,p,o,n=new Uint8Array(32),m=a.length
if(m===32)B.j.aj(n,0,a)
else for(s=m===0,r=0;r<32;++r)n[r]=s?0:(a[B.c.a7(r,m)]^r*17)>>>0
q=new Uint32Array(60)
for(r=0;r<8;++r){m=r*4
q[r]=(n[m]<<24|n[m+1]<<16|n[m+2]<<8|n[m+3])>>>0}p=[0,1,2,4,8,16,32,64,128,27,54]
for(r=8;r<60;++r){o=q[r-1]
m=B.c.a7(r,8)
if(m===0){o=o<<8|o>>>24
o=($.cy[o>>>24&255]<<24|$.cy[o>>>16&255]<<16|$.cy[o>>>8&255]<<8|$.cy[o&255])^p[B.c.a3(r,8)]<<24}else if(m===4)o=$.cy[o>>>24&255]<<24|$.cy[o>>>16&255]<<16|$.cy[o>>>8&255]<<8|$.cy[o&255]
q[r]=(q[r-8]^o)>>>0}return q},
fQ:function fQ(a){this.a=a},
fR:function fR(a){this.a=a},
pR(){return new A.j0()},
j0:function j0(){},
qa(a,b){var s=new Uint8Array(b),r=new A.dE(a,s)
r.c=A.at(s,0,null)
return r},
dE:function dE(a,b){var _=this
_.a=a
_.b=b
_.c=$
_.d=!1
_.e=0
_.r=-1
_.x=_.w=null},
oZ(a,b,c){var s=t.L,r=t.N,q=t.S,p=A.a([],t.ei),o=A.a7([0,B.U],q,t.ch)
A.pR()
return new A.m0(b,a,A.o(s,t.b7),A.aD(s),A.o(r,t.d9),A.o(r,t.p),A.o(r,q),p,new A.cO(),new A.lW(o,A.aD(q)),!0)},
aW(a){var s=A.at(a,0,null)
return new A.ci(s.getUint32(0,!1),s.getUint32(4,!1),s.getUint32(8,!1),J.bm(B.j.gai(a),a.byteOffset+12,a.length-12))},
aq:function aq(a,b){this.a=a
this.b=b},
dF:function dF(a,b,c){var _=this
_.a=a
_.b=null
_.c=b
_.d=-1
_.e=null
_.f=$
_.r=c},
mc:function mc(){},
md:function md(a){this.a=a},
hu:function hu(a){this.a=a},
hI:function hI(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
n6:function n6(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=null
_.e=d},
cO:function cO(){this.c=this.b=this.a=null},
m0:function m0(a,b,c,d,e,f,g,h,i,j,k){var _=this
_.a=a
_.c=b
_.d=c
_.e=d
_.f=null
_.r=e
_.w=f
_.x=0
_.y=g
_.z=!1
_.Q=h
_.as=i
_.at=null
_.ax=j
_.ay=k},
m1:function m1(a){this.a=a},
m4:function m4(a){this.a=a},
ma:function ma(a){this.a=a},
mb:function mb(a){this.a=a},
m9:function m9(a,b,c){this.a=a
this.b=b
this.c=c},
m2:function m2(a,b){this.a=a
this.b=b},
m8:function m8(a,b){this.a=a
this.b=b},
m3:function m3(a,b,c){this.a=a
this.b=b
this.c=c},
m6:function m6(){},
m7:function m7(){},
m5:function m5(a){this.a=a},
dS:function dS(a,b){this.a=a
this.b=b},
lV:function lV(a,b){this.a=a
this.b=b},
lW:function lW(a,b){this.a=1
this.b=a
this.c=b},
ci:function ci(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
oE(a,b){var s,r=t.N,q=new A.h0(a,A.o(r,t.fr),A.o(r,t.gc),A.o(r,t.aW),A.o(r,t.da),A.a7(["main",A.aD(r)],r,t.cq))
q.f=A.pR()
r=new A.iw(a,A.o(r,t.eT),A.o(r,t.fM),A.o(r,t._),A.o(r,t.h2),A.o(r,t.b0),A.o(r,t.dT),A.o(r,t.eO),A.o(r,t.d5),A.o(r,t.f6))
q.b=r
s=A.oZ(a,1000,!0)
q.c=s
q.d=new A.mp(r,s,a,q.gfE())
q.e=new A.iv(a)
return q},
v2(a){var s,r
for(s=a.length,r=0;r<s;++r)if(A.pi(a[r].a))return!0
return!1},
pi(a){var s
if(a instanceof A.af){s=a.b.toLowerCase()
if(s==="count"||s==="sum"||s==="avg"||s==="min"||s==="max")return!0}if(a instanceof A.a1)return A.pi(a.c)||A.pi(a.d)
return!1},
vp(a){var s,r,q,p,o,n,m=B.a.V(a)
if(B.a.U(m,"[")&&B.a.B(m,"]")){s=B.a.V(B.a.O(m,1,m.length-1))
if(J.O(s)===0)return new A.a5(A.a([],t.n))
try{q=J.oA(s,",")
p=A.z(q).i("h<1,W>")
o=A.r(new A.h(q,new A.o4(),p),p.i("u.E"))
r=o
return new A.a5(r)}catch(n){return null}}return null},
v3(a,b,c,d,e,f){var s,r,q,p,o,n,m,l,k,j,i
for(s=e+1,r=a.$flags|0;s<=f;++s){q=a[s]
p=b[q]
o=c[q]
n=d[q]
m=s-1
while(m>=e){l=a[m]
k=b[l]
j=!0
if(!(k>p))if(k===p){i=c[l]
if(!(i>o))if(i===o)j=d[l]>n
else j=!1}else j=!1
if(!j)break
r&2&&A.i(a)
a[m+1]=l;--m}r&2&&A.i(a)
a[m+1]=q}},
pm(a,b,c,d,e,f){var s,r,q,p,o,n,m,l,k,j,i,h,g
if(e>=f)return
if(f-e<=15){A.v3(a,b,c,d,e,f)
return}s=B.c.bV(e+f,1)
if(b[a[e]]>b[a[s]])A.fM(a,e,s)
if(b[a[e]]>b[a[f]])A.fM(a,e,f)
if(b[a[s]]>b[a[f]])A.fM(a,s,f)
r=a[s]
q=b[r]
p=c[r]
o=d[r]
for(n=a.$flags|0,m=f,l=e;l<=m;){for(;;){k=a[l]
j=b[k]
if(j<q){++l
continue}if(j>q)break
i=c[k]
if(i<p){++l
continue}if(i>p)break
if(d[k]<o){++l
continue}break}for(;;){k=a[m]
j=b[k]
if(j>q){--m
continue}if(j<q)break
i=c[k]
if(i>p){--m
continue}if(i<p)break
if(d[k]>o){--m
continue}break}if(l<=m){h=a[l]
g=a[m]
n&2&&A.i(a)
a[l]=g
a[m]=h;++l;--m}}if(e<m)A.pm(a,b,c,d,e,m)
if(l<f)A.pm(a,b,c,d,l,f)},
pn(a,b,c,d,e,f,g){var s,r,q,p,o,n,m
if(f>=g)return
s=B.c.bV(f+g,1)
if(A.im(a[f],a[s],b,c,d,e)>0)A.fM(a,f,s)
if(A.im(a[f],a[g],b,c,d,e)>0)A.fM(a,f,g)
if(A.im(a[s],a[g],b,c,d,e)>0)A.fM(a,s,g)
r=a[s]
for(q=a.$flags|0,p=g,o=f;o<=p;){while(A.im(a[o],r,b,c,d,e)<0)++o
while(A.im(a[p],r,b,c,d,e)>0)--p
if(o<=p){n=a[o]
m=a[p]
q&2&&A.i(a)
a[o]=m
a[p]=n;++o;--p}}if(f<p)A.pn(a,b,c,d,e,f,p)
if(o<g)A.pn(a,b,c,d,e,o,g)},
im(a,b,c,d,e,f){var s,r,q,p,o
for(s=a*f,r=b*f,q=0;q<f;++q){p=B.h.A(c[s+q],c[r+q])
if(p!==0)return p}o=B.c.A(d[a],d[b])
if(o!==0)return o
return B.c.A(e[a],e[b])},
fM(a,b,c){var s=a[b],r=a[c]
a.$flags&2&&A.i(a)
a[b]=r
a[c]=s},
B:function B(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
mG:function mG(){},
h0:function h0(a,b,c,d,e,f){var _=this
_.a=a
_.f=_.e=_.d=_.c=_.b=$
_.r=b
_.w=null
_.x=c
_.y=d
_.z=e
_.as=f},
iQ:function iQ(){},
jJ:function jJ(a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q){var _=this
_.a=a
_.b="admin"
_.c=b
_.d=c
_.e=d
_.f=e
_.r=f
_.w=g
_.x=h
_.y=i
_.z=j
_.Q=k
_.as=l
_.at=m
_.ax=null
_.ay=n
_.ch=o
_.CW=p
_.cx=q
_.cy=$},
kR:function kR(a,b){this.a=a
this.b=b},
kT:function kT(a,b){this.a=a
this.b=b},
kS:function kS(){},
kp:function kp(a){this.a=a},
kq:function kq(a){this.a=a},
ko:function ko(a){this.a=a},
jO:function jO(a){this.a=a},
jN:function jN(a){this.a=a},
jT:function jT(){},
jU:function jU(){},
jV:function jV(){},
jW:function jW(){},
jX:function jX(){},
jY:function jY(){},
jZ:function jZ(){},
k_:function k_(){},
k0:function k0(){},
jP:function jP(){},
jQ:function jQ(){},
jS:function jS(a){this.a=a},
kB:function kB(a){this.a=a},
kb:function kb(a,b){this.a=a
this.b=b},
kc:function kc(a){this.a=a},
ka:function ka(){},
kd:function kd(a,b){this.a=a
this.b=b},
kg:function kg(a,b){this.a=a
this.b=b},
kh:function kh(a,b){this.a=a
this.b=b},
ki:function ki(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
kj:function kj(a){this.a=a},
kk:function kk(){},
kl:function kl(a){this.a=a},
km:function km(a,b){this.a=a
this.b=b},
kn:function kn(a,b){this.a=a
this.b=b},
ke:function ke(a,b){this.a=a
this.b=b},
kf:function kf(a){this.a=a},
k2:function k2(a,b){this.a=a
this.b=b},
k3:function k3(a){this.a=a},
k4:function k4(a){this.a=a},
k5:function k5(a){this.a=a},
kC:function kC(a){this.a=a},
kD:function kD(a,b){this.a=a
this.b=b},
kE:function kE(){},
kF:function kF(a){this.a=a},
kG:function kG(a){this.a=a},
kH:function kH(a){this.a=a},
kI:function kI(a){this.a=a},
kJ:function kJ(a){this.a=a},
kK:function kK(){},
kL:function kL(a){this.a=a},
jK:function jK(a,b){this.a=a
this.b=b},
ku:function ku(a){this.a=a},
kv:function kv(a){this.a=a},
kw:function kw(){},
kz:function kz(){},
kx:function kx(a,b,c){this.a=a
this.b=b
this.c=c},
ky:function ky(){},
jM:function jM(a){this.a=a},
k1:function k1(a){this.a=a},
kA:function kA(a){this.a=a},
jR:function jR(){},
kr:function kr(a){this.a=a},
ks:function ks(a){this.a=a},
kt:function kt(a){this.a=a},
k8:function k8(a){this.a=a},
k9:function k9(a){this.a=a},
kM:function kM(a){this.a=a},
kN:function kN(){},
kO:function kO(){},
kP:function kP(){},
kQ:function kQ(){},
jL:function jL(a,b){this.a=a
this.b=b},
k6:function k6(a){this.a=a},
k7:function k7(a){this.a=a},
bk:function bk(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f},
o4:function o4(){},
cs:function cs(a,b,c){this.a=a
this.b=b
this.c=c},
i_:function i_(a,b){var _=this
_.a=a
_.b=b
_.c=!1
_.d=null
_.e=0
_.f=!1},
r_(a){var s,r,q=a.length
for(s=0;s<q;++s){r=a.charCodeAt(s)
if(r>=65&&r<=90)return a.toLowerCase()}return a},
wf(a,b){var s,r,q,p,o,n,m
if(!B.a.E(b,"_")&&!B.a.E(b,"\\")){s=B.a.U(b,"%")
r=B.a.B(b,"%")
q=s?1:0
p=b.length
if(!B.a.E(B.a.O(b,q,p-(r?1:0)),"%")){o=A.r_(a)
q=s?1:0
n=B.a.O(b,q,p-(r?1:0)).toLowerCase()
if(s&&r)return B.a.E(o,n)
else if(s)return B.a.B(o,n)
else if(r)return B.a.U(o,n)
else return o===n}}q=A.iq(b)
q=A.T(q,"\\%","%")
q=A.T(q,"\\_","_")
q=A.T(q,"%",".*")
m=A.aI("^"+A.T(q,"_",".")+"$",!1)
return m.b.test(a)},
K(a){var s,r,q={}
if(a instanceof A.ag||a instanceof A.aR||a instanceof A.cr)return A.bY(a)
s=A.S(a)
r=A.bY(a)
q.a=null
q.b=!1
return new A.lM(q,r,s)},
bY(a){var s,r,q,p,o,n,m,l,k,j,i,h
if(a instanceof A.co)return new A.lb(a)
if(a instanceof A.ba)return new A.lc(A.K(a.b),a.c,a.d)
if(a instanceof A.aR)return new A.ld(a.c)
if(a instanceof A.ag)return new A.lo(A.cd(a.b))
if(a instanceof A.cr)return new A.lz(new A.a5(a.b))
if(a instanceof A.H){s={}
r=a.b
if(r.length===0)return new A.lE()
q=B.b.R(r,".").toLowerCase()
if(q==="true")return new A.lF()
if(q==="false")return new A.lG()
s.a=s.b=null
s.c=1
return new A.lH(s,r.length>1,r,a)}if(a instanceof A.a1){s=a.c
p=A.bY(s)
o=a.d
n=A.bY(o)
switch(a.b.toLowerCase()){case"+":return new A.lI(p,n)
case"-":return new A.lJ(p,n)
case"*":return new A.le(p,n)
case"/":return new A.lf(p,n)
case"%":m=!1
if(s instanceof A.H)if(o instanceof A.H){m=o.b
m=B.b.R(m,".").toLowerCase()==="found"||B.b.R(m,".").toLowerCase()==="notfound"}if(m)return new A.lg((B.b.R(s.b,".")+"%"+B.b.R(o.b,".")).toLowerCase())
return new A.lh(p,n)
case"||":return new A.li(p,n)
case"=":return new A.lj(p,n)
case"!=":case"<>":return new A.lk(p,n)
case"<":return new A.ll(p,n)
case"<=":return new A.lm(p,n)
case">":return new A.ln(p,n)
case">=":return new A.lp(p,n)
case"~":s={}
l=A.bY(o)
s.a=s.b=null
return new A.lq(s,p,l)
case"like":case"ilike":if(o instanceof A.ag||o instanceof A.aR){s={}
k=s.a=s.b=s.c=null
s.d=s.e=s.f=s.r=!1
s.w=""
return new A.lr(s,o instanceof A.aR?o.c:k,n,p)}return new A.ls(p,n)
case"in":return new A.lt(p,n)
case"and":return new A.lu(p,n)
case"or":return new A.lv(p,n)
default:return new A.lw()}}if(a instanceof A.d9){s=a.b
o=A.z(s).i("h<1,+condFn,thenFn(k(w<e,k>),k(w<e,k>))>")
j=A.r(new A.h(s,new A.lx(),o),o.i("u.E"))
s=a.c
return new A.ly(j,s!=null?A.bY(s):null)}if(a instanceof A.cb)return new A.lA(A.bY(a.b),a.c)
if(a instanceof A.af){i=A.S(a)
s=a.c
o=A.z(s).i("h<1,k(w<e,k>)>")
h=A.r(new A.h(s,new A.lB(),o),o.i("u.E"))
return new A.lC(i,a.b.toLowerCase(),h,a)}return new A.lD()},
q3(a){var s,r,q,p,o,n,m=B.a.V(a)
if(B.a.U(m,"[")&&B.a.B(m,"]")){s=B.a.V(B.a.O(m,1,m.length-1))
if(J.O(s)===0)return new A.a5(A.a([],t.n))
try{q=J.oA(s,",")
p=A.z(q).i("h<1,W>")
o=A.r(new A.h(q,new A.lL(),p),p.i("u.E"))
r=o
return new A.a5(r)}catch(n){return null}}return null},
oU(a){var s,r,q=A.aI("POINT\\s*\\(\\s*([0-9.-]+)\\s+([0-9.-]+)\\s*\\)",!1).bq(a)
if(q!=null){s=q.b
r=s[1]
r.toString
r=A.cw(r)
s=s[2]
s.toString
return A.a([r,A.cw(s)],t.n)}return null},
tu(a){var s,r,q,p,o,n,m,l,k
if(B.a.U(B.a.V(a),"["))try{s=t.j.a(B.o.ag(a))
r=J.bG(s,new A.lK(),t.o)
r=A.r(r,r.$ti.i("u.E"))
return r}catch(q){return null}p=A.aI("POLYGON\\s*\\(\\s*\\(([^)]+)\\)\\s*\\)",!1).bq(a)
if(p!=null){o=p.b[1].split(",")
n=A.a([],t.gy)
for(r=o.length,m=t.n,l=0;l<r;++l){k=B.a.cQ(B.a.V(o[l]),A.aI("\\s+",!0))
if(k.length>=2)n.push(A.a([A.cw(k[0]),A.cw(k[1])],m))}return n}return null},
lM:function lM(a,b,c){this.a=a
this.b=b
this.c=c},
lb:function lb(a){this.a=a},
la:function la(){},
lc:function lc(a,b,c){this.a=a
this.b=b
this.c=c},
ld:function ld(a){this.a=a},
lo:function lo(a){this.a=a},
lz:function lz(a){this.a=a},
lE:function lE(){},
lF:function lF(){},
lG:function lG(){},
lH:function lH(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
lI:function lI(a,b){this.a=a
this.b=b},
lJ:function lJ(a,b){this.a=a
this.b=b},
le:function le(a,b){this.a=a
this.b=b},
lf:function lf(a,b){this.a=a
this.b=b},
lg:function lg(a){this.a=a},
lh:function lh(a,b){this.a=a
this.b=b},
li:function li(a,b){this.a=a
this.b=b},
lj:function lj(a,b){this.a=a
this.b=b},
lk:function lk(a,b){this.a=a
this.b=b},
ll:function ll(a,b){this.a=a
this.b=b},
lm:function lm(a,b){this.a=a
this.b=b},
ln:function ln(a,b){this.a=a
this.b=b},
lp:function lp(a,b){this.a=a
this.b=b},
lq:function lq(a,b,c){this.a=a
this.b=b
this.c=c},
lr:function lr(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
ls:function ls(a,b){this.a=a
this.b=b},
lt:function lt(a,b){this.a=a
this.b=b},
lu:function lu(a,b){this.a=a
this.b=b},
lv:function lv(a,b){this.a=a
this.b=b},
lw:function lw(){},
lx:function lx(){},
ly:function ly(a,b){this.a=a
this.b=b},
lA:function lA(a,b){this.a=a
this.b=b},
lB:function lB(){},
lC:function lC(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
l3:function l3(){},
l4:function l4(a){this.a=a},
l5:function l5(){},
l6:function l6(a){this.a=a},
l7:function l7(a){this.a=a},
l8:function l8(a){this.a=a},
l9:function l9(a){this.a=a},
lD:function lD(){},
lL:function lL(){},
lK:function lK(){},
wj(b2){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0=null,b1=A.oZ(b0,100,!0)
b1.f=b2.d
p=b2.f
o=p!=null?A.K(p):b0
n=A.a([],t.b)
for(m=b2.b,p=b2.c,l=b2.a,k=b2.r,j=k!=null,i=b2.e,h=i.b,i=i.a+".",g=t.N,f=t.r;m.cM(0,p);m=m.ap(0,1)){e=b1.C(l,m)
d=A.aT(e)
for(c=0;c<d;++c){s=A.ab(e,c)
if(s!=null){r=null
try{q=A.aW(s)
r=A.a0(q.d,b0,b0)}catch(b){r=A.a0(s,b0,b0)}a=A.o(g,f)
for(a0=0;a0<h.length;++a0){a.k(0,h[a0],J.Y(r,a0))
a.k(0,i+h[a0],J.Y(r,a0))}if(o!=null){a1=o.$1(a)
if(!(a1 instanceof A.p&&a1.a===1))a2=a1 instanceof A.j&&a1.a>0
else a2=!0
if(!a2)continue}if(j){a3=A.o(g,f)
for(a4=k.length,a5=0;a5<k.length;k.length===a4||(0,A.n)(k),++a5){a6=k[a5]
a7=a6.a
a8=A.bM(a7,a)
a9=a6.b
if(a9==null)a9=a7 instanceof A.H?B.b.R(a7.b,"."):a8.l(0)
a3.k(0,a9,a8)}n.push(a3)}else n.push(a)}}b1.u(l,m,!1)}b1.dv()
return n},
wi(c4){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2,b3,b4,b5,b6,b7,b8,b9,c0,c1,c2=null,c3=A.oZ(c2,100,!0)
c3.f=c4.d
p=c4.f
o=p!=null?A.K(p):c2
p=c4.w
n=p!=null?A.K(p):c2
m=A.o(t.gY,t.W)
p=c4.x
if(p!=null)for(l=p.length,k=0;k<p.length;p.length===l||(0,A.n)(p),++k){j=p[k]
i=j.a
h=i instanceof A.af
if(h&&i.c.length!==0)m.k(0,j,A.K(i.c[0]))
else if(!h)m.k(0,j,A.K(i))}l=t.r
g=A.o(l,t.bf)
for(f=c4.b,h=c4.c,e=c4.a,d=n!=null,c=c4.e,b=c.b,c=c.a+".",a=t.N;f.cM(0,h);f=f.ap(0,1)){a0=c3.C(e,f)
a1=A.aT(a0)
for(a2=0;a2<a1;++a2){s=A.ab(a0,a2)
if(s!=null){r=null
try{q=A.aW(s)
r=A.a0(q.d,c2,c2)}catch(a3){r=A.a0(s,c2,c2)}a4=A.o(a,l)
for(a5=0;a5<b.length;++a5){a4.k(0,b[a5],J.Y(r,a5))
a4.k(0,c+b[a5],J.Y(r,a5))}if(o!=null){a6=o.$1(a4)
if(!(a6 instanceof A.p&&a6.a===1))a7=a6 instanceof A.j&&a6.a>0
else a7=!0
if(!a7)continue}if(d){a8=g.I(n.$1(a4),new A.oq(a4))
p.toString
a8.dN(a4,p,m)}else{a8=g.I(A.v(1),new A.or(a4))
p.toString
a8.dN(a4,p,m)}}}c3.u(e,f,!1)}a9=A.a([],t.b)
for(h=new A.an(g,g.$ti.i("an<1,2>")).gJ(0);h.p();){b0=h.d
b1=b0.a
a8=b0.b
b2=A.o(a,l)
b2.k(0,"group_key",b1)
for(e=p.length,d=a8.x,c=a8.w,b=a8.r,b3=a8.e,b4=a8.f,b5=a8.d,b6=a8.c,b7=a8.b,k=0;k<p.length;p.length===e||(0,A.n)(p),++k){j=p[k]
i=j.a
b8=j.b
if(b8==null)b8=A.S(i)
if(i instanceof A.af){b9=i.b.toLowerCase()
if(b9==="count"){c0=b7.h(0,b8)
b2.k(0,b8,A.v(c0==null?0:c0))}else if(b9==="sum"){c1=b6.h(0,b8)
if(c1==null)b2.k(0,b8,new A.d())
else{c0=b5.h(0,b8)
b2.k(0,b8,c0===!0?new A.j(c1):A.v(B.h.bd(c1)))}}else if(b9==="avg"){c0=b4.h(0,b8)
b2.k(0,b8,new A.j(c0==null?0:c0))
c0=b3.h(0,b8)
b2.k(0,b8+"_count",A.v(c0==null?0:c0))}else if(b9==="min"){c0=b.h(0,b8)
b2.k(0,b8,c0==null?new A.d():c0)}else if(b9==="max"){c0=c.h(0,b8)
b2.k(0,b8,c0==null?new A.d():c0)}else{c0=d.h(0,b8)
b2.k(0,b8,c0==null?new A.d():c0)}}else{c0=d.h(0,b8)
b2.k(0,b8,c0==null?new A.d():c0)}}a9.push(b2)}c3.dv()
return a9},
mh:function mh(a,b,c,d,e,f,g,h,i){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g
_.w=h
_.x=i},
oq:function oq(a){this.a=a},
or:function or(a){this.a=a},
dG:function dG(a,b,c,d,e,f,g,h,i){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g
_.w=h
_.x=i
_.y=null
_.z=0},
me:function me(a){this.a=a},
mf:function mf(a){this.a=a},
mg:function mg(){},
bM(d0,d1){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2,b3,b4,b5,b6,b7,b8,b9,c0,c1,c2,c3,c4,c5,c6,c7=null,c8="euclidean",c9=A.S(d0)
if(d1.F(c9)){j=d1.h(0,c9)
j.toString
return j}for(j=A.E(d1),i=j.i("aL<1>"),h=new A.aL(d1,d1.r,d1.e,i);h.p();){g=h.d
if(g.toLowerCase()===c9.toLowerCase()){j=d1.h(0,g)
j.toString
return j}}if(d0 instanceof A.co){s=$.eB
if(s==null)return new A.d()
$.cQ.push(d1)
try{r=s.aA(d0.b)
if(r!=null){q=r.gfu()
if(t.j.b(q)){if(J.O(q)===0){h=A.a([],t.K)
return new A.aP(h)}if(J.O(q)===1&&J.Y(q,0).length===1){h=J.Y(q,0)[0]
return h}h=q
g=A.z(h).i("h<1,k>")
h=A.r(new A.h(h,new A.of(),g),g.i("u.E"))
return new A.aP(h)}}return new A.d()}finally{if($.cQ.length!==0)$.cQ.pop()}}if(d0 instanceof A.ba){f=A.bM(d0.b,d1)
if(f instanceof A.M){e=f.ga2()
if(t.f.b(e))d=e.h(0,d0.c)
else if(t.j.b(e)){c=A.a4(d0.c,c7)
d=c!=null&&c>=0&&c<J.O(e)?J.Y(e,c):c7}else d=c7
if(d==null)return new A.d()
if(d0.d)if(typeof d=="string")return new A.m(d)
else return new A.m(B.o.bB(d))
else if(A.fJ(d))return A.v(d)
else if(typeof d=="number")return new A.j(d)
else if(typeof d=="number")return new A.j(d)
else if(A.fI(d))return A.v(d?1:0)
else return new A.M(d,c7)}return new A.d()}if(d0 instanceof A.aR)return new A.d()
if(d0 instanceof A.ag)return A.cd(d0.b)
if(d0 instanceof A.cr)return new A.a5(d0.b)
if(d0 instanceof A.H){b=d0.b
if(b.length===0)return new A.d()
a=B.b.R(b,".")
a0=a.toLowerCase()
if(a0==="true")return new A.M(!0,c7)
if(a0==="false")return new A.M(!1,c7)
if(d1.F(a)){j=d1.h(0,a)
j.toString
return j}if(b.length>=2){a1=b[0]+"."+b[1]
if(d1.F(a1)){h=d1.h(0,a1)
h.toString
if(h instanceof A.M)return h.aY(B.b.ad(b,2))}}if(b.length>=2){a2=b[0]
if(d1.F(a2)){h=d1.h(0,a2)
h.toString
if(h instanceof A.M)return h.aY(B.b.ad(b,1))}for(i=new A.aL(d1,d1.r,d1.e,i),h="."+a2;i.p();){g=i.d
if(B.a.B(g,h)){g=d1.h(0,g)
g.toString
if(g instanceof A.M)return g.aY(B.b.ad(b,1))}}}a3=b[0]
for(j=new A.an(d1,j.i("an<1,2>")).gJ(0),i="."+a3;j.p();){a4=j.d
a5=a4.a
if(a5===a3||B.a.B(a5,i))return a4.b}a6=A.p6(B.b.R(b,"."))
if(a6!=null)return a6
return new A.d()}if(d0 instanceof A.a1){a7=A.bM(d0.c,d1)
a8=A.bM(d0.d,d1)
switch(d0.b.toLowerCase()){case"+":return a7.ap(0,a8)
case"-":return a7.aG(0,a8)
case"*":return a7.P(0,a8)
case"/":return a7.aD(0,a8)
case"%":j=a7 instanceof A.p
if(j&&a8 instanceof A.p)return A.v(B.c.a7(a7.a,a8.a))
else if(j&&a8 instanceof A.j)return new A.j(B.c.a7(a7.a,a8.a))
else{j=a7 instanceof A.j
if(j&&a8 instanceof A.p)return new A.j(B.h.a7(a7.a,a8.a))
else if(j&&a8 instanceof A.j)return new A.j(B.h.a7(a7.a,a8.a))}return new A.d()
case"||":return a7.aJ(a8)
case"=":return A.v(a7.A(0,a8)===0?1:0)
case"!=":case"<>":return A.v(a7.A(0,a8)!==0?1:0)
case"<":return A.v(a7.A(0,a8)<0?1:0)
case"<=":return A.v(a7.A(0,a8)<=0?1:0)
case">":return A.v(a7.A(0,a8)>0?1:0)
case">=":return A.v(a7.A(0,a8)>=0?1:0)
case"like":j=a7.l(0)
i=A.iq(a8.l(0))
i=A.T(i,"\\%","%")
i=A.T(i,"\\_","_")
i=A.T(i,"%",".*")
a9=A.aI("^"+A.T(i,"_",".")+"$",!1)
return A.v(a9.b.test(j)?1:0)
case"in":if(a8 instanceof A.aP){j=a8.a
i=j.length
b1=0
for(;;){if(!(b1<j.length)){b0=!1
break}if(a7.A(0,j[b1])===0){b0=!0
break}j.length===i||(0,A.n)(j);++b1}return A.v(b0?1:0)}else return A.v(a7.A(0,a8)===0?1:0)
case"and":if(!(a7 instanceof A.p&&a7.a===1))b2=a7 instanceof A.j&&a7.a>0
else b2=!0
if(!(a8 instanceof A.p&&a8.a===1))b3=a8 instanceof A.j&&a8.a>0
else b3=!0
return A.v(b2&&b3?1:0)
case"or":if(!(a7 instanceof A.p&&a7.a===1))b2=a7 instanceof A.j&&a7.a>0
else b2=!0
if(!(a8 instanceof A.p&&a8.a===1))b3=a8 instanceof A.j&&a8.a>0
else b3=!0
return A.v(b2||b3?1:0)
default:return new A.d()}}if(d0 instanceof A.af){a3=d0.b.toLowerCase()
j=d0.c
i=A.z(j).i("h<1,k>")
b4=A.r(new A.h(j,new A.og(d1),i),i.i("u.E"))
if(a3==="in_list")return new A.aP(b4)
i=$.eB
if(i!=null){p=i
i=p.a.b
i===$&&A.b()
o=i.y.h(0,a3.toLowerCase())
if(o!=null){n=A.Z(p.c,t.N,t.r)
p.c.v(0)
b5=0
for(;;){j=o.c
j===$&&A.b()
if(!(b5<j.length))break
j=o.c
j===$&&A.b()
b6=j[b5]
b7=b5<b4.length?b4[b5]:new A.d()
p.c.k(0,b6.a,b7);++b5}m=new A.d()
try{j=o.e
j===$&&A.b()
i=j.length
b1=0
for(;b1<j.length;j.length===i||(0,A.n)(j),++b1){l=j[b1]
p.aA(l)}}catch(b8){j=A.aV(b8)
if(j instanceof A.dN){k=j
m=k.a}else throw b8}finally{p.c.v(0)
p.c.X(0,n)}return m}}if(a3==="vector_distance"){i=b4.length
i=i===2||i===3}else i=!1
if(i){b9=b4[0]
c0=b4[1]
if(b4.length===3){c1=b4[2]
c2=c1 instanceof A.m?c1.a.toLowerCase():c8}else c2=c8
if(b9 instanceof A.m){c3=A.qS(b9.a)
b9=c3==null?b9:c3}if(c0 instanceof A.m){c4=A.qS(c0.a)
c0=c4==null?c0:c4}if(b9 instanceof A.a5&&c0 instanceof A.a5)switch(c2){case"cosine":return new A.j(b9.cm(c0))
case"dot":return new A.j(b9.cp(c0))
case"euclidean":default:return new A.j(b9.co(c0))}}if(a3==="cast"&&b4.length===2){c5=b4[0]
c6=J.x(t.gV.a(j[1]).b)
if(c5 instanceof A.d)return new A.d()
if(c6==="DataType.text")return new A.m(c5.l(0))
else if(c6==="DataType.integer"){if(c5 instanceof A.p)return c5
if(c5 instanceof A.j)return A.v(B.h.bd(c5.a))
j=A.a4(c5.l(0),c7)
return A.v(j==null?0:j)}else if(c6==="DataType.double"){if(c5 instanceof A.j)return c5
if(c5 instanceof A.p)return new A.j(c5.a)
j=A.aH(c5.l(0))
return new A.j(j==null?0:j)}}if(a3==="json_set"&&b4.length===3)return A.r8(b4[0],b4[1],b4[2])
if(a3==="json_remove"&&b4.length===2)return A.r7(b4[0],b4[1])
if(a3==="json_array")return A.r5(b4)
if(a3==="json_object")return A.r6(b4)
return new A.d()}return new A.d()},
qk(a,b,c,d){var s=new A.hG(a,b,c,d)
s.fR(a,b,c,d)
return s},
pP(a,b,c){var s=new A.fX(a,b,c,A.a([],t.f8),A.o(t.N,t.r))
s.fO(a,b,c)
return s},
tk(a,b,c,d,e,f){var s=new A.he(f,e,b,c,a,d)
s.fP(a,b,c,d,e,f)
return s},
er(a,b){var s=new A.cE(a,b)
s.c=A.K(b)
return s},
hD(a,b){var s=new A.dK(a,b)
s.fQ(a,b)
return s},
oB(a){var s=t.N,r=t.S,q=t.i,p=t.r
A.q6(a,s,p)
return new A.d6(A.o(s,r),A.o(s,q),A.o(s,t.y),A.o(s,r),A.o(s,q),A.o(s,p),A.o(s,p),A.o(s,p))},
qn(a,b,c){var s=new A.dP(a,b,c,A.a([],t.b))
s.d=A.K(b)
return s},
qS(a){var s,r,q,p,o,n,m=B.a.V(a)
if(B.a.U(m,"[")&&B.a.B(m,"]")){s=B.a.V(B.a.O(m,1,m.length-1))
if(J.O(s)===0)return new A.a5(A.a([],t.n))
try{q=J.oA(s,",")
p=A.z(q).i("h<1,W>")
o=A.r(new A.h(q,new A.o3(),p),p.i("u.E"))
r=o
return new A.a5(r)}catch(n){return null}}return null},
qO(a,b,c){var s,r,q,p,o,n,m,l,k,j=null
try{s=A.aW(b)
n=a.a
r=n.ga5()
q=n.ax
n=r
m=n==null?j:n.a
p=m==null?0:m
n=r
l=n==null?j:n.b
o=l==null?B.u:l
if(q.aC(s.a,s.b,p,o)){n=A.a0(s.d,c,j)
return n}return j}catch(k){n=A.a0(b,c,j)
return n}},
qu(a,b){var s=new A.hO(a,b,A.aD(t.Y))
s.fT(a,b)
return s},
P:function P(){},
of:function of(){},
og:function og(a){this.a=a},
hG:function hG(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=null
_.x=_.w=_.r=_.f=$},
mL:function mL(a){this.a=a},
mM:function mM(a){this.a=a},
dR:function dR(a,b){this.a=a
this.b=b},
hb:function hb(a,b){var _=this
_.a=a
_.b=b
_.c=null
_.d=0},
j8:function j8(a,b){this.a=a
this.b=b},
j9:function j9(a,b){this.a=a
this.b=b},
h7:function h7(a){this.a=a
this.b=null
this.c=0},
fX:function fX(a,b,c,d,e){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=!1
_.r=_.f=$
_.w=e},
iN:function iN(a){this.a=a},
iO:function iO(a){this.a=a},
iP:function iP(a){this.a=a},
he:function he(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=null
_.w=0
_.y=_.x=null
_.ax=_.at=_.as=_.Q=$},
jG:function jG(a){this.a=a},
jH:function jH(a){this.a=a},
jI:function jI(){},
cE:function cE(a,b){this.a=a
this.b=b
this.c=$},
dK:function dK(a,b){this.a=a
this.b=b
this.c=$},
mn:function mn(){},
mo:function mo(){},
d6:function d6(a,b,c,d,e,f,g,h){var _=this
_.b=a
_.c=b
_.d=c
_.e=d
_.f=e
_.r=f
_.w=g
_.x=h},
bW:function bW(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=null
_.f=0},
jl:function jl(){},
jk:function jk(){},
jm:function jm(){},
jj:function jj(){},
jn:function jn(a,b,c){this.a=a
this.b=b
this.c=c},
ji:function ji(){},
jh:function jh(){},
jo:function jo(){},
ds:function ds(a,b,c,d,e,f,g,h,i,j,k,l){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g
_.w=h
_.x=i
_.z=_.y=$
_.Q=j
_.at=_.as=null
_.ax=0
_.ay=k
_.ch=l
_.CW=null},
jq:function jq(){},
jp:function jp(a){this.a=a},
hs:function hs(a,b,c,d,e,f,g,h,i,j){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g
_.w=h
_.x=$
_.y=i
_.z=j
_.Q=null
_.as=0
_.at=!1
_.ax=null},
lY:function lY(a){this.a=a},
dP:function dP(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=$
_.e=d
_.f=0},
mO:function mO(a){this.a=a},
hU:function hU(a,b){var _=this
_.a=a
_.b=b
_.c=null
_.d=0},
ne:function ne(){},
nf:function nf(a){this.a=a},
ng:function ng(){},
nh:function nh(a,b){this.a=a
this.b=b},
ha:function ha(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=null
_.w=0},
dA:function dA(a){this.a=a
this.b=0},
hE:function hE(a,b){var _=this
_.a=a
_.b=b
_.c=null
_.d=0},
mK:function mK(a){this.a=a},
cK:function cK(a,b,c){var _=this
_.a=a
_.b=b
_.c=c
_.e=_.d=0},
o3:function o3(){},
dt:function dt(a,b,c,d,e,f,g,h,i,j,k,l){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g
_.w=h
_.x=i
_.y=$
_.Q=_.z=null
_.as=j
_.at=k
_.ax=l
_.ay=null},
jE:function jE(a){this.a=a},
dr:function dr(a,b,c,d,e,f,g){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g
_.w=$},
jg:function jg(){},
hc:function hc(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.r=f
_.w=null
_.x=0},
jD:function jD(a,b){this.a=a
this.b=b},
hi:function hi(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.r=f
_.w=null
_.x=0},
l1:function l1(a,b){this.a=a
this.b=b},
bC:function bC(a){this.a=a},
hO:function hO(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.d=c
_.e=null
_.f=-1},
na:function na(a){this.a=a},
nb:function nb(){},
hg:function hg(a,b){var _=this
_.a=a
_.b=b
_.d=_.c=null
_.e=!1},
kU:function kU(a){this.a=a},
h5:function h5(a,b){var _=this
_.a=a
_.b=b
_.d=_.c=null
_.e=!1},
j1:function j1(a){this.a=a},
h1:function h1(a,b){this.a=a
this.b=b},
ph(a){var s
if(a instanceof A.eF)return a
if(a instanceof A.a1){s=A.ph(a.c)
return s==null?A.ph(a.d):s}return null},
mp:function mp(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
mq:function mq(a){this.a=a},
ms:function ms(){},
mr:function mr(a){this.a=a},
mF:function mF(a){this.a=a},
mz:function mz(a){this.a=a},
mw:function mw(a){this.a=a},
mA:function mA(){},
mB:function mB(){},
mC:function mC(){},
mD:function mD(a){this.a=a},
mE:function mE(a){this.a=a},
mv:function mv(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
mu:function mu(a){this.a=a},
mx:function mx(a){this.a=a},
my:function my(){},
mt:function mt(a,b){this.a=a
this.b=b},
bj:function bj(a,b,c){this.a=a
this.b=b
this.c=c},
jF:function jF(a,b,c){this.a=a
this.b=b
this.c=c},
tc(a){var s,r,q,p=$.oM
if(p!=null)if(p.b==null)p.b=$.cN.$0()
p=$.oM
r=p==null?null:p.gbY()
if(r==null)r=0
$.oL=!1
s=0
try{s=A.tJ()}catch(q){s=0}return new A.j2($.pS,r,a,95,s,A.q8($.pT,t.fU))},
j2:function j2(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f},
j3:function j3(){},
bT(a,b,c){var s,r,q,p,o
if(c===0)return new A.d()
s=b+1
r=c-1
switch(a.getUint8(b)){case 0:return new A.d()
case 1:if(r===1)return A.v(a.getInt8(s))
else if(r===2)return A.v(a.getInt16(s,!1))
else if(r===4)return A.v(a.getInt32(s,!1))
else if(r===8)return A.v(B.r.c2(a,s))
throw A.c(A.cf("Invalid DbInt length: "+r,null,null))
case 2:return new A.j(a.getFloat64(s,!1))
case 3:return new A.m(B.a5.ag(J.bm(B.r.gai(a),a.byteOffset+s,r)))
case 4:q=B.c.a3(r,8)
p=J.dv(q,t.i)
for(o=0;o<q;++o)p[o]=a.getFloat64(s+o*8,!1)
return new A.a5(p)
case 5:return new A.M(null,J.bm(B.r.gai(a),a.byteOffset+s,r))
case 8:return new A.aG(a.getUint8(s)!==0)
case 9:return new A.bp(B.a5.ag(J.bm(B.r.gai(a),a.byteOffset+s,r)))
case 10:B.r.c2(a,s)
return void 1
case 11:return new A.b0(new Uint8Array(A.bx(J.bm(B.r.gai(a),a.byteOffset+s,r))))
case 12:return new A.a8(a.getFloat64(s,!1))
default:return new A.d()}},
cd(a){var s
if(a==null)return new A.d()
if(A.fI(a))return new A.aG(a)
if(a instanceof A.aw)return new A.bo(a)
if(t.p.b(a))return new A.b0(a)
if(A.fJ(a)){if(a>=-100&&a<=1000)return $.pz()[a+100]
return A.v(a)}if(typeof a=="number")return new A.j(a)
if(typeof a=="number")return new A.j(a)
if(typeof a=="string")return new A.m(a)
if(t.o.b(a))return new A.a5(a)
if(t.j.b(a)){s=J.bc(a)
if(s.cr(a,new A.iW())){s=s.bc(a,new A.iX(),t.i)
s=A.r(s,s.$ti.i("u.E"))
return new A.a5(s)}return new A.M(a,null)}if(t.f.b(a))return new A.M(a,null)
return new A.m(J.x(a))},
oG(a){return new A.p(a)},
v(a){if(a===0)return $.R()
if(a===1)return $.U()
if(a>=-100&&a<=1000)return $.pz()[a+100]
return new A.p(a)},
w5(a3,a4){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2
if(a4.length===0)return new A.M(B.o.ag(a3),null)
s=a3.length
for(r=0,q=0;p=a4.length,r<p;){o=a4[r]
for(n=0,m=0,l=!1,k=!1,j=-1,i=-1;q<s;){h=a3.charCodeAt(q)
if(k){++q
k=!1
continue}if(h===92){++q
k=!0
continue}if(h===34){l=!l
if(l)j=q+1
else i=q;++q
continue}if(!l)if(h===123)++n
else if(h===125)--n
else if(h===91)++m
else if(h===93)--m
else if(h===58&&n===1&&m===0)if(j!==-1&&i!==-1)if(B.a.O(a3,j,i)===o){++q
while(g=q<s,g){f=a3.charCodeAt(q)
if(f===32||f===9||f===10||f===13)++q
else break}if(r===p-1){if(g){e=a3.charCodeAt(q)
if(e>=48&&e<=57||e===45){d=q+1
while(d<s){c=a3.charCodeAt(d)
if(c>=48&&c<=57||c===46||c===101||c===69||c===45||c===43)++d
else break}b=B.a.V(B.a.O(a3,q,d))
a=A.a4(b,null)
if(a==null)a=A.aH(b)
if(a!=null)return A.cd(a)}else if(e===34){d=q+1
for(a0=d,a1=!1;p=a0<s,p;){c=a3.charCodeAt(a0)
if(a1)a1=!1
else{a1=c===92
if(!a1)if(c===34)break}++a0}if(p)return new A.m(B.a.O(a3,d,a0))}else if(B.a.c6(a3,"true",q))return A.v(1)
else if(B.a.c6(a3,"false",q))return A.v(0)
else if(B.a.c6(a3,"null",q))return new A.d()
else if(e===123||e===91)break}break}else if(g&&a3.charCodeAt(q)===123){a2=r+1;++q
r=a2
break}else return new A.d()}++q}if(q>=s)break}return new A.M(B.o.ag(a3),null).em(a4)},
rg(a){if(B.a.U(a,"$."))a=B.a.az(a,2)
else if(B.a.U(a,"$"))a=B.a.az(a,1)
if(a.length===0)return A.a([],t.s)
return A.a(a.split("."),t.s)},
r3(a){if(t.f.b(a)||t.j.b(a))return B.o.ag(B.o.bB(a))
return a},
ir(a,b,c){var s,r,q,p=null
if(b.length===0)return c
s=B.b.gH(b)
if(b.length===1)if(t.f.b(a)){r=A.Z(a,t.N,t.z)
r.k(0,s,c)
return r}else if(t.j.b(a)){q=A.a4(s,p)
if(q!=null&&q>=0){r=A.a6(a,!0,t.z)
while(r.length<=q)r.push(p)
r[q]=c
return r}}else{q=A.a4(s,p)
if(q!=null&&q>=0){r=[]
while(r.length<=q)r.push(p)
r[q]=c
return r}else return A.a7([s,c],t.N,t.z)}else if(t.f.b(a)){r=A.Z(a,t.N,t.z)
r.k(0,s,A.ir(r.h(0,s),B.b.ad(b,1),c))
return r}else if(t.j.b(a)){q=A.a4(s,p)
if(q!=null&&q>=0){r=A.a6(a,!0,t.z)
while(r.length<=q)r.push(p)
r[q]=A.ir(r[q],B.b.ad(b,1),c)
return r}}else{q=A.a4(s,p)
if(q!=null&&q>=0){r=[]
while(r.length<=q)r.push(p)
r[q]=A.ir(p,B.b.ad(b,1),c)
return r}else return A.a7([s,A.ir(p,B.b.ad(b,1),c)],t.N,t.z)}return a},
py(a,b){var s,r,q
if(b.length===0)return a
s=B.b.gH(b)
if(b.length===1){if(t.f.b(a)){r=A.Z(a,t.N,t.z)
r.S(0,s)
return r}else if(t.j.b(a)){q=A.a4(s,null)
if(q!=null&&q>=0&&q<J.O(a)){r=A.a6(a,!0,t.z)
B.b.aN(r,q)
return r}}}else if(t.f.b(a)){if(a.F(s)){r=A.Z(a,t.N,t.z)
r.k(0,s,A.py(r.h(0,s),B.b.ad(b,1)))
return r}}else if(t.j.b(a)){q=A.a4(s,null)
if(q!=null&&q>=0&&q<J.O(a)){r=A.a6(a,!0,t.z)
r[q]=A.py(r[q],B.b.ad(b,1))
return r}}return a},
px(a){if(a instanceof A.d)return null
if(a instanceof A.p)return a.a
if(a instanceof A.j)return a.a
if(a instanceof A.m)return a.a
if(a instanceof A.M)return a.ga2()
if(a instanceof A.a5)return a.a
return a.ga2()},
r8(a,b,c){var s,r,q,p
if(b instanceof A.d)return new A.d()
r=A.rg(b.l(0))
s=null
if(a instanceof A.M)s=A.r3(a.ga2())
else if(a instanceof A.m)try{s=B.o.ag(a.a)}catch(q){s=a.a}else if(a instanceof A.d)s=null
else s=a.ga2()
p=A.px(c)
return new A.M(A.ir(s,r,p),null)},
r7(a,b){var s,r,q
if(b instanceof A.d)return new A.d()
r=A.rg(b.l(0))
s=null
if(a instanceof A.M)s=A.r3(a.ga2())
else if(a instanceof A.m)try{s=B.o.ag(a.a)}catch(q){s=a.a}else if(a instanceof A.d)s=null
else s=a.ga2()
return new A.M(A.py(s,r),null)},
r5(a){var s=A.z(a).i("h<1,@>"),r=A.r(new A.h(a,A.wr(),s),s.i("u.E"))
return new A.M(r,null)},
r6(a){var s,r
if(B.c.a7(a.length,2)!==0)throw A.c(A.q("JSON_OBJECT requires an even number of arguments"))
s=A.o(t.N,t.z)
for(r=0;r<a.length;r+=2)s.k(0,a[r].l(0),A.px(a[r+1]))
return new A.M(s,null)},
p6(a){var s,r,q,p,o,n,m=a.toLowerCase()
for(s=$.cQ.length-1,r="."+a;s>=0;--s){q=$.cQ[s]
if(q.F(a))return q.h(0,a)
for(p=q.gZ(),p=p.gJ(p);p.p();){o=p.gD()
if(o.toLowerCase()===m)return q.h(0,o)}for(p=q.gbZ(),p=p.gJ(p);p.p();){o=p.gD()
n=o.a
if(B.a.B(n,r)||n===a)return o.b}}return null},
k:function k(){},
iW:function iW(){},
iX:function iX(){},
d:function d(){},
p:function p(a){this.a=a},
j:function j(a){this.a=a},
m:function m(a){this.a=a},
a5:function a5(a){this.a=a},
M:function M(a,b){this.a=a
this.b=null
this.c=b},
aN:function aN(a,b){this.a=a
this.b=b},
aP:function aP(a){this.a=a},
iV:function iV(){},
aG:function aG(a){this.a=a},
bp:function bp(a){this.a=a},
bo:function bo(a){this.a=a},
b0:function b0(a){this.a=a},
iU:function iU(){},
a8:function a8(a){this.a=a},
p3(a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p){var s
if(h==null)s=g!=null?A.a([g],t.R):B.b9
else s=h
return new A.aS(l,n,c,b,m,s,o,d,e,k,i,j,p,f,a)},
S(a){var s,r,q,p,o,n=", ",m=a.a
if(m!=null)return m
if(a instanceof A.aR)s=a.b
else if(a instanceof A.ag)s=J.x(a.b)
else if(a instanceof A.H)s=B.b.R(a.b,".")
else if(a instanceof A.a1)s=A.S(a.c)+" "+a.b+" "+A.S(a.d)
else if(a instanceof A.af){m=a.c
s=a.b.toLowerCase()+"("+new A.h(m,A.io(),A.z(m).i("h<1,e>")).R(0,n)+")"}else if(a instanceof A.bK){m=a.d
r=m.length===0?"":"PARTITION BY "+new A.h(m,A.io(),A.z(m).i("h<1,e>")).R(0,n)
m=a.e
if(m!=null){q=A.S(m.a)
m=m.b?"ASC":"DESC"
p="ORDER BY "+q+" "+m}else p=""
m=A.a([],t.s)
if(r.length!==0)m.push(r)
if(p.length!==0)m.push(p)
s=a.b.toUpperCase()+"() OVER ("+B.b.R(m," ")+")"}else if(a instanceof A.cr)s="["+B.b.R(a.b,n)+"]"
else if(a instanceof A.ba){o=a.d?"->>":"->"
s=A.S(a.b)+o+"'"+a.c+"'"}else if(a instanceof A.co)s="(SELECT ...)"
else if(a instanceof A.dO){m=a.b
s="ROLLUP("+new A.h(m,A.io(),A.z(m).i("h<1,e>")).R(0,n)+")"}else if(a instanceof A.dj){m=a.b
s="CUBE("+new A.h(m,A.io(),A.z(m).i("h<1,e>")).R(0,n)+")"}else if(a instanceof A.cF){m=a.b
s="GROUPING SETS("+new A.h(m,new A.oh(),A.z(m).i("h<1,e>")).R(0,n)+")"}else s=a instanceof A.cb?"CAST("+A.S(a.b)+" AS "+a.c.b.toUpperCase()+")":"Instance of '"+A.eS(a)+"'"
return a.a=s},
av:function av(a,b){this.a=a
this.b=b},
y:function y(){},
L:function L(){},
ag:function ag(a){this.b=a
this.a=null},
aR:function aR(a,b){this.b=a
this.c=b
this.a=null},
H:function H(a){this.b=a
this.a=null},
a1:function a1(a,b,c){var _=this
_.b=a
_.c=b
_.d=c
_.a=null},
af:function af(a,b){this.b=a
this.c=b
this.a=null},
bK:function bK(a,b,c,d){var _=this
_.b=a
_.c=b
_.d=c
_.e=d
_.a=null},
cr:function cr(a){this.b=a
this.a=null},
ba:function ba(a,b,c){var _=this
_.b=a
_.c=b
_.d=c
_.a=null},
co:function co(a){this.b=a
this.a=null},
dO:function dO(a){this.b=a
this.a=null},
dj:function dj(a){this.b=a
this.a=null},
cF:function cF(a){this.b=a
this.a=null},
e4:function e4(a){this.b=a},
b_:function b_(a,b,c,d,e,f,g,h,i,j){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g
_.w=h
_.x=i
_.y=j},
ai:function ai(a,b){this.a=a
this.b=b},
br:function br(a,b,c,d,e,f,g){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g},
dD:function dD(a,b){this.a=a
this.b=b},
G:function G(){},
hS:function hS(){},
hw:function hw(a){this.b=a},
hx:function hx(a,b,c){this.a=a
this.b=b
this.c=c},
dg:function dg(a,b,c,d,e){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e},
dc:function dc(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
eF:function eF(a,b){this.b=a
this.c=b
this.a=null},
d7:function d7(a,b){this.a=a
this.b=b},
bP:function bP(a,b,c,d,e,f,g,h){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g
_.w=h},
cH:function cH(a,b,c,d,e,f,g,h){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g
_.w=h},
dk:function dk(a,b){this.a=a
this.b=b},
fj:function fj(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
aS:function aS(a,b,c,d,e,f,g,h,i,j,k,l,m,n,o){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g
_.w=h
_.x=i
_.y=j
_.z=k
_.Q=l
_.as=m
_.at=n
_.ax=o},
di:function di(a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r){var _=this
_.ay=a
_.ch=b
_.CW=c
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h
_.f=i
_.r=j
_.w=k
_.x=l
_.y=m
_.z=n
_.Q=o
_.as=p
_.at=q
_.ax=r},
cS:function cS(a,b){this.a=a
this.b=b},
du:function du(a){this.a=a},
dm:function dm(a){this.a=a},
hT:function hT(a,b,c){this.a=a
this.b=b
this.c=c},
h_:function h_(a,b){this.a=a
this.b=b},
ce:function ce(a,b){this.a=a
this.b=b},
dH:function dH(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
e6:function e6(a,b){this.a=a
this.b=b},
h2:function h2(a,b){this.a=a
this.b=b},
ew:function ew(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
fm:function fm(a,b){this.a=a
this.b=b},
eh:function eh(a){this.a=a},
e7:function e7(){},
eb:function eb(){},
f0:function f0(){},
ev:function ev(a,b,c){this.a=a
this.b=b
this.c=c},
eZ:function eZ(a,b,c){this.a=a
this.b=b
this.c=c},
f4:function f4(a){this.a=a},
f3:function f3(a,b){this.a=a
this.b=b},
ef:function ef(a){this.a=a},
fk:function fk(a){this.a=a},
df:function df(a,b,c,d,e){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e},
dd:function dd(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
dq:function dq(){},
ep:function ep(a){this.a=a},
d8:function d8(a){this.a=a},
f8:function f8(){},
f6:function f6(a){this.a=a},
de:function de(a,b,c){this.a=a
this.b=b
this.c=c},
hv:function hv(a){this.a=a},
cB:function cB(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
cA:function cA(a,b,c,d,e){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e},
e9:function e9(a,b){this.a=a
this.b=b},
eX:function eX(a){this.a=a},
dN:function dN(a){this.a=a},
f2:function f2(a){this.a=a},
f_:function f_(a){this.a=a},
eW:function eW(a){this.a=a},
eN:function eN(a){this.a=a},
eq:function eq(a,b){this.a=a
this.b=b},
ea:function ea(a){this.a=a},
dh:function dh(a,b,c,d,e,f,g,h){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g
_.w=h},
dU:function dU(a,b){this.a=a
this.b=b},
d9:function d9(a,b){this.b=a
this.c=b
this.a=null},
cb:function cb(a,b){this.b=a
this.c=b
this.a=null},
ej:function ej(a,b){this.a=a
this.b=b},
cC:function cC(a){this.a=a},
f5:function f5(a){this.a=a},
f7:function f7(){},
eP:function eP(a){this.a=a},
fh:function fh(a){this.a=a},
ei:function ei(a){this.a=a},
et:function et(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
cc:function cc(a,b,c){this.a=a
this.b=b
this.c=c},
eg:function eg(a){this.a=a},
el:function el(a,b){this.a=a
this.b=b},
oh:function oh(){},
c_:function c_(a){var _=this
_.a=a
_.b=0
_.d=_.c=1},
c1:function c1(a){this.a=a
this.c=this.b=0},
mi:function mi(){},
mj:function mj(){},
mk:function mk(){},
f:function f(a,b){this.a=a
this.b=b},
N:function N(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
iv:function iv(a){this.a=a},
fU(a,b,c){var s=new A.fT(a,b,c),r=c*8
s.z=r
s.y=50
r=4+50*r
s.Q=r
r+=200
s.as=r
r+=100
s.at=r
s.ax=r+4
return s},
aZ:function aZ(a,b){this.a=a
this.b=b},
fT:function fT(a,b,c){var _=this
_.a=a
_.b=b
_.c=c
_.e=_.d=0
_.f=!1
_.x=_.w=_.r=null
_.ax=_.at=_.as=_.Q=_.z=_.y=$},
fV:function fV(a,b){this.a=a
this.b=b},
qh(a,b){var s=new A.eT(a,b),r=new A.c1(new A.c_(b).bu()).dI()
if(r instanceof A.cB){s.c=r.b
s.d=r.c}else A.al(A.q("Invalid procedure SQL stored in catalog"))
return s},
tI(a){return A.qh(a.h(0,"name"),a.h(0,"sql"))},
pV(a,b){var s=new A.eu(a,b),r=new A.c1(new A.c_(b).bu()).dI()
if(r instanceof A.cA){s.c=r.b
s.d=r.c
s.e=r.d}else A.al(A.q("Invalid function SQL stored in catalog"))
return s},
tf(a){return A.pV(a.h(0,"name"),a.h(0,"sql"))},
qr(a,b,c,d,e,f){var s=new A.cR(c,f,a,e,b,d),r=new A.c1(new A.c_(d).bu()).dI()
if(r instanceof A.dh){s.r=r.f
s.w=r.r}else A.al(A.q("Invalid trigger SQL stored in catalog"))
return s},
tV(a){var s=a.h(0,"name"),r=a.h(0,"timing"),q=a.h(0,"event"),p=a.h(0,"tableName"),o=a.h(0,"forEachRow")
if(o==null)o=!1
return A.qr(q,o,s,a.h(0,"sql"),p,r)},
bJ(a,b,c,d,e,f,g,h,i,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1){var s=null,r=f==null?A.a9(d.length,!1,!1,t.y):f,q=a0==null?A.a9(d.length,!1,!1,t.y):a0,p=h==null?A.a9(d.length,s,!1,t.T):h,o=g==null?A.a9(d.length,s,!1,t.T):g,n=e==null?A.a9(d.length,!1,!1,t.y):e,m=b==null?A.a9(d.length,s,!1,t.O):b,l=a==null?A.a9(d.length,s,!1,t.O):a,k=b1==null?A.a([],t.dG):b1,j=c==null?A.a9(d.length,s,!1,t.T):c
r=new A.c4(a5,d,i,a3,r,q,p,o,n,m,l,k,j,a4,a2,a1,a6,a9,a8,b0,a7==null?A.a([],t.s):a7)
r.fS(a,b,c,d,e,f,g,h,i,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1)
return r},
tU(b2){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b="columnDefaultValues",a=null,a0="columnCheckExpressions",a1="columnPrimaryKey",a2="columnUnique",a3="columnReferencesTable",a4="columnReferencesColumn",a5="columnOnDeleteCascade",a6="policies",a7="foreignOptions",a8="partitionChildren",a9=t.N,b0=A.a6(b2.h(0,"columnNames"),!0,a9),b1=t.O
if(b2.F(b)){s=J.bG(t.j.a(b2.h(0,b)),new A.mQ(),b1)
r=A.r(s,s.$ti.i("u.E"))}else r=A.a9(b0.length,a,!1,b1)
if(b2.F(a0)){b1=J.bG(t.j.a(b2.h(0,a0)),new A.mR(),b1)
q=A.r(b1,b1.$ti.i("u.E"))}else q=A.a9(b0.length,a,!1,b1)
b1=b2.h(0,"name")
s=t.j
p=J.bG(s.a(b2.h(0,"columnTypes")),new A.mS(),t.q)
p=A.r(p,p.$ti.i("u.E"))
o=b2.h(0,"isColumnar")
if(o==null)o=!1
n=b2.F(a1)?A.a6(b2.h(0,a1),!0,t.y):a
m=b2.F(a2)?A.a6(b2.h(0,a2),!0,t.y):a
l=b2.F(a3)?A.a6(b2.h(0,a3),!0,t.T):a
k=b2.F(a4)?A.a6(b2.h(0,a4),!0,t.T):a
j=b2.F(a5)?A.a6(b2.h(0,a5),!0,t.y):a
if(b2.F(a6)){s=J.bG(s.a(b2.h(0,a6)),new A.mT(),t.dV)
s=A.r(s,s.$ti.i("u.E"))}else s=a
i=b2.h(0,"isForeign")
if(i==null)i=!1
h=b2.h(0,"foreignServer")
g=b2.h(0,a7)!=null?A.Z(b2.h(0,a7),a9,a9):a
f=b2.h(0,"partitionByColumn")
e=b2.h(0,"partitionOfParent")
d=b2.h(0,"partitionFromValue")
c=b2.h(0,"partitionToValue")
return A.bJ(q,r,a,b0,j,n,k,l,p,m,g,h,o,i,b1,f,b2.h(0,a8)!=null?A.a6(b2.h(0,a8),!0,a9):a,d,e,c,s)},
tN(a){return new A.dM(a.h(0,"name"),a.h(0,"fromTable"),a.h(0,"toTable"),a.h(0,"fromKey"),a.h(0,"toKey"))},
tl(a){return new A.b9(a.h(0,"name"),a.h(0,"tableName"),a.h(0,"columnName"),a.h(0,"usingMethod"))},
qo(a){var s=t.N
return new A.bu(a,A.o(s,t.dP),A.o(s,t.cv))},
qp(a){var s="columnStats",r="histograms",q=a.h(0,"rowCount"),p=A.qo(q==null?0:q)
if(a.F(s))t.a.a(a.h(0,s)).a0(0,new A.n1(p))
if(a.F(r))t.a.a(a.h(0,r)).a0(0,new A.n2(p))
return p},
eT:function eT(a,b){var _=this
_.a=a
_.b=b
_.d=_.c=$},
eu:function eu(a,b){var _=this
_.a=a
_.b=b
_.e=_.d=_.c=$},
cR:function cR(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.w=_.r=$},
bt:function bt(a,b){this.a=a
this.b=b},
c4:function c4(a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,a0,a1){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g
_.w=h
_.x=i
_.y=j
_.z=k
_.Q=l
_.as=m
_.at=n
_.ax=o
_.ay=p
_.ch=q
_.CW=r
_.cx=s
_.cy=a0
_.db=a1
_.fx=_.fr=_.dy=_.dx=$},
mU:function mU(){},
mV:function mV(){},
mW:function mW(){},
mX:function mX(){},
mY:function mY(){},
mZ:function mZ(){},
n_:function n_(){},
n0:function n0(){},
mQ:function mQ(){},
mR:function mR(){},
mS:function mS(){},
mT:function mT(){},
dM:function dM(a,b,c,d,e){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e},
b9:function b9(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
iw:function iw(a,b,c,d,e,f,g,h,i,j){var _=this
_.a=a
_.c=b
_.d=c
_.e=d
_.f=e
_.r=f
_.w=g
_.x=h
_.y=i
_.z=j},
iB:function iB(a,b,c){this.a=a
this.b=b
this.c=c},
iC:function iC(){},
iD:function iD(){},
ix:function ix(){},
iE:function iE(a){this.a=a},
iF:function iF(a){this.a=a},
iG:function iG(a){this.a=a},
iH:function iH(a){this.a=a},
iI:function iI(a){this.a=a},
iJ:function iJ(a){this.a=a},
iK:function iK(a){this.a=a},
iA:function iA(){},
iz:function iz(a,b){this.a=a
this.b=b},
iy:function iy(a){this.a=a},
bs:function bs(a,b,c){this.a=a
this.b=b
this.c=c},
db:function db(a){this.a=a},
bu:function bu(a,b,c){this.a=a
this.b=b
this.c=c},
n3:function n3(){},
n4:function n4(){},
n1:function n1(a){this.a=a},
n2:function n2(a){this.a=a},
tC(a){var s,r,q,p="al",o="ic"
a=B.a.V(a.toLowerCase())
s=a.length
if(s<3)return a
if(B.a.B(a,"sses"))a=B.a.O(a,0,s-2)
else if(B.a.B(a,"ies"))a=B.a.O(a,0,s-2)+"i"
else if(!B.a.B(a,"ss"))if(B.a.B(a,"s")&&!B.a.B(a,"us")&&!B.a.B(a,"is")&&!B.a.B(a,"as"))a=B.a.O(a,0,s-1)
if(B.a.B(a,"eed")){r=B.a.O(a,0,a.length-3)
if(A.dI(r)>0)a=r+"ee"}else if(B.a.B(a,"ing")){r=B.a.O(a,0,a.length-3)
if(A.p_(r))a=A.qb(r)}else if(B.a.B(a,"ed")){r=B.a.O(a,0,a.length-2)
if(A.p_(r))a=A.qb(r)}if(B.a.B(a,"y")&&A.p_(B.a.O(a,0,a.length-1)))a=B.a.O(a,0,a.length-1)+"i"
if(B.a.B(a,"ational"))a=A.aM(a,"ational","ate")
else if(B.a.B(a,"tional"))a=A.aM(a,"tional","tion")
else if(B.a.B(a,"izer"))a=A.aM(a,"izer","ize")
else if(B.a.B(a,"alli"))a=A.aM(a,"alli",p)
else if(B.a.B(a,"entli"))a=A.aM(a,"entli","ent")
else if(B.a.B(a,"eli"))a=A.aM(a,"eli","e")
else if(B.a.B(a,"ousli"))a=A.aM(a,"ousli","ous")
else if(B.a.B(a,"alism"))a=A.aM(a,"alism",p)
else if(B.a.B(a,"ation"))a=A.aM(a,"ation","ate")
else if(B.a.B(a,"aliti"))a=A.aM(a,"aliti",p)
else if(B.a.B(a,"iviti"))a=A.aM(a,"iviti","ive")
else if(B.a.B(a,"biliti"))a=A.aM(a,"biliti","ble")
if(B.a.B(a,"icate"))a=A.aM(a,"icate",o)
else if(B.a.B(a,"ative"))a=A.aM(a,"ative","")
else if(B.a.B(a,"alize"))a=A.aM(a,"alize",p)
else if(B.a.B(a,"iciti"))a=A.aM(a,"iciti",o)
else if(B.a.B(a,"ical"))a=A.aM(a,"ical",o)
else if(B.a.B(a,"ful"))a=A.aM(a,"ful","")
else if(B.a.B(a,"ness"))a=A.aM(a,"ness","")
if(B.a.B(a,p)||B.a.B(a,"ance")||B.a.B(a,"ence")||B.a.B(a,"er")||B.a.B(a,o)||B.a.B(a,"able")||B.a.B(a,"ible")||B.a.B(a,"ant")||B.a.B(a,"ement")||B.a.B(a,"ment")||B.a.B(a,"ent")){r=B.a.O(a,0,a.length-A.tB(a,A.a(["al","ance","ence","er","ic","able","ible","ant","ement","ment","ent"],t.s)).length)
if(A.dI(r)>1)a=r}else if(B.a.B(a,"ion")){r=B.a.O(a,0,a.length-3)
if((B.a.B(r,"s")||B.a.B(r,"t"))&&A.dI(r)>1)a=r}if(B.a.B(a,"e")){r=B.a.O(a,0,a.length-1)
q=A.dI(r)
if(q<=1)s=q===1&&!A.qc(r)
else s=!0
if(s)a=r}return B.a.B(a,"l")&&A.qd(a)&&A.dI(a)>1?B.a.O(a,0,a.length-1):a},
dI(a){var s,r,q,p,o
for(s=a.length,r=0,q=!1,p=0;p<s;++p){o=A.eO(a,p)
if(o&&!q)q=!0
else if(!o&&q){++r
q=!1}}return r},
p_(a){var s,r
for(s=a.length,r=0;r<s;++r)if(A.eO(a,r))return!0
return!1},
eO(a,b){var s=a[b]
if(B.a.E("aeiou",s))return!0
if(s==="y"&&b>0&&!A.eO(a,b-1))return!0
return!1},
qb(a){if(B.a.B(a,"at")||B.a.B(a,"bl")||B.a.B(a,"iz"))return a+"e"
if(A.qd(a)&&!B.a.B(a,"l")&&!B.a.B(a,"s")&&!B.a.B(a,"z"))return B.a.O(a,0,a.length-1)
if(A.dI(a)===1&&A.qc(a))return a+"e"
return a},
qd(a){var s,r=a.length
if(r<2)return!1
s=a[r-1]
return s===a[r-2]&&!B.a.E("aeiou",s)},
qc(a){var s,r,q=a.length
if(q<3)return!1
s=q-1
r=a[s]
return!A.eO(a,s)&&A.eO(a,q-2)&&!A.eO(a,q-3)&&r!=="w"&&r!=="x"&&r!=="y"},
aM(a,b,c){var s=B.a.O(a,0,a.length-b.length)
if(A.dI(s)>0)return s+c
return a},
tB(a,b){var s,r
for(s=0;s<11;++s){r=b[s]
if(B.a.B(a,r))return r}return""},
rj(a){var s,r,q,p=A.aI("[^\\w\\s]",!0),o=B.a.cQ(A.T(a,p," ").toLowerCase(),A.aI("\\s+",!0)),n=A.a([],t.s)
for(p=o.length,s=0;s<o.length;o.length===p||(0,A.n)(o),++s){r=o[s]
if(r.length===0)continue
if(B.cQ.E(0,r))continue
q=A.tC(r)
if(q.length!==0)n.push(q)}return n},
bH:function bH(a,b){this.a=a
this.b=b},
h9:function h9(a,b){this.a=a
this.b=b},
j4:function j4(){},
j5:function j5(a,b){this.a=a
this.b=b},
j7:function j7(a){this.a=a},
j6:function j6(a){this.a=a},
oN(a,b,c){var s=A.a([],t.ae),r=new A.i8()
r.dU(42)
return new A.js(b,1/Math.log(16),!1,c,s,r)},
cG:function cG(a,b,c,d,e){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e},
js:function js(a,b,c,d,e,f){var _=this
_.a=a
_.f=b
_.r=c
_.w=d
_.x=e
_.y=null
_.z=-1
_.Q=f},
jt:function jt(){},
ju:function ju(a){this.a=a},
jv:function jv(a){this.a=a},
jw:function jw(){},
jx:function jx(a,b){this.a=a
this.b=b},
jy:function jy(){},
jz:function jz(){},
jA:function jA(a,b){this.a=a
this.b=b},
jB:function jB(){},
jC:function jC(a){this.a=a},
ay:function ay(a,b){this.a=a
this.b=b},
q0(a,b,c){return new A.hh(b,!1,c,A.a([],t.G),A.o(t.S,t.gB),A.a([],t.D))},
bq:function bq(a,b,c){this.a=a
this.b=b
this.c=c},
hh:function hh(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=10
_.e=3
_.f=d
_.r=e
_.w=f},
kV:function kV(){},
kW:function kW(){},
kX:function kX(){},
kY:function kY(){},
kZ:function kZ(){},
l_:function l_(){},
l0:function l0(){},
bv:function bv(a,b){this.a=a
this.b=b},
bE:function bE(a,b){this.a=a
this.b=b},
tM(a0,a1,a2,a3,a4,a5){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a=a0===$.ox()?$.rI():A.at(a0,0,null)
a.$flags&2&&A.i(a,11)
a.setUint32(0,a2,!1)
a.setUint32(4,a3,!1)
a.setUint32(8,a4,!1)
s=a1.length
a.setUint16(12,s,!1)
r=14+s*2
for(q=a0.$flags|0,p=0;p<s;++p){a.setUint16(14+p*2,r-12,!1)
o=a1[p]
if(o instanceof A.d){q&2&&A.i(a0)
a0[r]=0;++r}else if(o instanceof A.p){q&2&&A.i(a0)
a0[r]=1
n=o.a
if(n>=-128&&n<=127){a.setInt8(r+1,n)
r+=2}else if(n>=-32768&&n<=32767){a.setInt16(r+1,n,!1)
r+=3}else{m=n>=-2147483648&&n<=2147483647
l=r+1
if(m){a.setInt32(l,n,!1)
r+=5}else B.r.c4(a,l,n)}}else if(o instanceof A.j){q&2&&A.i(a0)
a0[r]=2
a.setFloat64(r+1,o.a,!1)
r+=9}else if(o instanceof A.m){q&2&&A.i(a0)
a0[r]=3
k=o.a
j=k.length
if(j<=1024){m=r+1
B.j.a8(a0,m,m+j,new A.da(k))
r+=1+j}else{i=B.x.aB(k)
h=a5.dO(i)
a0[r]=6
a.setUint32(r+1,h,!1)
a.setUint32(r+5,i.length,!1)
r+=9}}else if(o instanceof A.a5){q&2&&A.i(a0)
a0[r]=4
m=o.a
l=J.X(m)
g=l.gt(m)
for(f=r+1,e=0;e<g;++e)a.setFloat64(f+e*8,l.h(m,e),!1)
r+=1+g*8}else if(o instanceof A.M){q&2&&A.i(a0)
a0[r]=5
m=o.a
d=B.o.bB(m==null?o.a=B.o.ag(o.gaR()):m)
j=d.length
e=0
for(;;){if(!(e<j)){c=!0
break}if(d.charCodeAt(e)>127){c=!1
break}++e}if(c){m=r+1
if(j>1024){i=new Uint8Array(A.bx(new A.da(d)))
h=a5.dO(i)
a0[r]=7
a.setUint32(m,h,!1)
a.setUint32(r+5,i.length,!1)
r+=9}else{B.j.a8(a0,m,m+j,new A.da(d))
r+=1+j}}else{i=B.x.aB(d)
m=i.length
l=r+1
if(m>1024){h=a5.dO(i)
a0[r]=7
a.setUint32(l,h,!1)
a.setUint32(r+5,m,!1)
r+=9}else{B.j.a8(a0,l,l+m,i)
r+=1+m}}}else if(o instanceof A.aG){q&2&&A.i(a0)
a0[r]=8
m=o.a?1:0
a0[r+1]=m
r+=2}else if(o instanceof A.bp){q&2&&A.i(a0)
a0[r]=9
i=B.x.aB(o.a)
m=r+1
l=i.length
B.j.a8(a0,m,m+l,i)
r+=1+l}else if(o instanceof A.bo){q&2&&A.i(a0)
a0[r]=10
B.r.c4(a,r+1,o.a.a)}else if(o instanceof A.b0){q&2&&A.i(a0)
a0[r]=11
m=r+1
l=o.a
f=l.length
B.j.a8(a0,m,m+f,l)
r+=1+f}else if(o instanceof A.a8){q&2&&A.i(a0)
a0[r]=12
a.setFloat64(r+1,o.a,!1)
r+=9}else{i=o.al()
b=r+i.length
B.j.a8(a0,r,b,i)
r=b}}return r},
p1(a){var s,r,q=a.length,p=2+q*2,o=A.z(a).i("h<1,bb>"),n=A.r(new A.h(a,new A.mI(),o),o.i("u.E")),m=B.b.iG(n,0,new A.mJ()),l=new Uint8Array(p+m),k=A.at(l,0,null)
k.$flags&2&&A.i(k,10)
k.setUint16(0,q,!1)
for(s=p,r=0;r<q;++r){k.$flags&2&&A.i(k,10)
k.setUint16(2+r*2,s,!1)
B.j.aj(l,s,n[r])
s+=n[r].length}return l},
a0(a,b,c){var s,r,q,p,o,n,m,l=A.at(a,0,null),k=l.getUint16(0,!1),j=A.a([],t.K)
for(s=a.length,r=c!=null,q=0;q<k;){p=l.getUint16(2+q*2,!1);++q
o=(q<k?l.getUint16(2+q*2,!1):s)-p
if(o>0){n=l.getUint8(p)
if(n===6)if(r){m=c.cE(l.getUint32(p+1,!1),l.getUint32(p+5,!1))
j.push(new A.m(new A.cZ(!1).bJ(m,0,null,!0)))}else j.push(new A.d())
else if(n===7)if(r)j.push(new A.M(null,c.cE(l.getUint32(p+1,!1),l.getUint32(p+5,!1))))
else j.push(new A.d())
else j.push(A.bT(l,p,o))}else j.push(new A.d())}if(b!=null&&j.length<b)while(j.length<b)j.push(new A.d())
return j},
qj(a,b,c,d){var s,r,q,p,o=a.getUint16(b,!1)
if(d>=o)return new A.d()
s=b+2
r=a.getUint16(s+d*2,!1)
q=d+1
p=q<o?a.getUint16(s+q*2,!1):c
return A.bT(a,b+r,p-r)},
f9(a){var s,r=a.c
r===$&&A.b()
r.$flags&2&&A.i(r,9)
r.setUint8(0,1)
r.setUint16(1,0,!1)
s=a.b.length
r.setUint16(3,s,!1)
a.w=0
a.x=s
a.d=!0},
aT(a){var s,r,q=a.b.length
if(q<5)return 0
s=a.c
s===$&&A.b()
if(s.getUint8(0)!==1)return 0
r=a.w
if(r==null){r=s.getUint16(1,!1)
a.w=r}return r>B.c.a3(q-5,4)?0:r},
qm(a){var s=a.x
if(s==null){s=a.c
s===$&&A.b()
s=a.x=s.getUint16(3,!1)}return s},
p4(a,b){var s,r,q,p,o,n,m=a.c
m===$&&A.b()
s=A.aT(a)
r=A.qm(a)
q=b.length
p=5+s*4
if(r-p<q+4)return!1
o=r-q
B.j.aj(a.b,o,b)
m.$flags&2&&A.i(m,10)
m.setUint16(p,o,!1)
m.setUint16(p+2,q,!1)
n=s+1
a.w=n
a.x=o
m.setUint16(1,n,!1)
m.setUint16(3,o,!1)
return a.d=!0},
cP(a,b,c){var s,r,q,p,o,n=a.c
n===$&&A.b()
s=A.aT(a)
r=A.qm(a)
q=5+s*4
if(r-q<c+4)return!1
p=r-c
B.j.aF(a.b,p,p+c,b,0)
n.$flags&2&&A.i(n,10)
n.setUint16(q,p,!1)
n.setUint16(q+2,c,!1)
o=s+1
a.w=o
a.x=p
n.setUint16(1,o,!1)
n.setUint16(3,p,!1)
return a.d=!0},
ab(a,b){var s,r,q,p,o=null,n=a.b,m=n.length
if(m<5)return o
s=a.c
s===$&&A.b()
if(b>=A.aT(a))return o
r=5+b*4
if(r+4>m)return o
q=s.getUint16(r,!1)
p=s.getUint16(r+2,!1)
if(p===0||q>=m||q+p>m)return o
return J.bm(B.j.gai(n),n.byteOffset+q,p)},
aO(a,b,c){var s=new A.ck(a,c,b)
s.d=new A.fg(a,b,c)
return s},
mI:function mI(){},
mJ:function mJ(){},
ck:function ck(a,b,c){var _=this
_.a=a
_.b=b
_.c=c
_.d=$
_.r=_.f=null
_.w=-1},
hF:function hF(a,b,c,d,e,f,g,h,i,j){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g
_.w=h
_.x=i
_.y=j
_.z=0
_.Q=null
_.at=_.as=0
_.ay=_.ax=null},
bQ:function bQ(a,b,c){this.a=a
this.b=b
this.c=c},
fg:function fg(a,b,c){this.a=a
this.b=b
this.c=c},
n9(){var s=0,r=A.b6(t.cE),q,p,o,n,m,l,k,j,i,h,g,f
var $async$n9=A.b7(function(a,b){if(a===1)return A.b3(b,r)
for(;;)switch(s){case 0:f=":memory:"
try{o=A.t7()
o=o.a
if(o==="")A.al(A.bn("Directory.createTemp called with an empty path. To use the system temp directory, use Directory.systemTemp",null))
if(!B.a.B(o,"/"))o=$.fO()&&B.a.B(o,"\\")
else o=!0
if(!o)A.D($.ot())
A.u3(A.bL(),void 1)
p=null}catch(e){f=":memory:"}m=A.oE(f,null)
s=3
return A.ar(m.br(),$async$n9)
case 3:o=new A.hM(m)
l=t.N
k=t.r
j=t.y
i=t._
h=t.de
l=new A.jJ(m,A.o(l,k),A.a([],t.s),A.a([],t.f0),A.o(t.k,t.W),A.o(l,t.gZ),A.o(l,t.dU),A.o(l,j),A.o(i,t.S),A.o(i,l),A.o(h,t.eT),A.o(h,t.fs),A.o(h,t.eg),A.o(l,j),A.o(l,k),A.o(l,t.g6),A.o(l,t.aI))
k=m.c
k===$&&A.b()
g=new A.cO()
k.Q.push(g)
l.cy=g
o.b=l
q=o
s=1
break
case 1:return A.b4(q,r)}})
return A.b5($async$n9,r)},
hM:function hM(a){this.a=a
this.b=$},
h3:function h3(a,b,c){this.a=a
this.b=b
this.c=c},
on(){var s=0,r=A.b6(t.H),q,p,o
var $async$on=A.b7(function(a,b){if(a===1)return A.b3(b,r)
for(;;)switch(s){case 0:o=$.pf
s=2
return A.ar(A.n9(),$async$on)
case 2:o.b=b
q=new A.oo()
if(typeof q=="function")A.al(A.bn("Attempting to rewrap a JS function.",null))
p=function(c,d){return function(e){return c(d,e,arguments.length)}}(A.uU,q)
p[$.os()]=q
v.G.executeUltSQL=p
A.wh("\u26a1 Real UltSQL 100% Pure Dart Engine Initialized in Browser!")
return A.b4(null,r)}})
return A.b5($async$on,r)},
o9(a){return A.vy(a)},
vy(a1){var s=0,r=A.b6(t.N),q,p=2,o=[],n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0
var $async$o9=A.b7(function(a2,a3){if(a2===1){o.push(a3)
s=p}for(;;)switch(s){case 0:a=new A.fc()
$.ou()
a.cS()
n=a
p=4
g=$.pf.b
if(g===$.pf)A.al(A.q5(""))
s=7
return A.ar(g.cD(a1),$async$o9)
case 7:m=a3
g=n
if(g.b==null)g.b=$.cN.$0()
g=B.h.fz(n.gbY()/1000,2)
f=m.a
e=m.b
d=A.z(e).i("h<1,t<e>>")
e=A.r(new A.h(e,new A.ob(),d),d.i("u.E"))
l=A.a7(["status","success","elapsedMs",g,"columns",f,"rows",e,"message",m.c],t.N,t.C)
c=B.o.dw(l,null)
q=c
s=1
break
p=2
s=6
break
case 4:p=3
a0=o.pop()
k=A.aV(a0)
g=n
if(g.b==null)g.b=$.cN.$0()
j=J.x(k)
i=A.vn(j)
h=A.a7(["status","error","elapsedMs",B.h.fz(n.gbY()/1000,2),"errorTitle",J.Y(i,"title"),"error",J.Y(i,"error"),"errorHint",J.Y(i,"hint"),"rawError",j],t.N,t.T)
q=B.o.dw(h,null)
s=1
break
s=6
break
case 3:s=2
break
case 6:case 1:return A.b4(q,r)
case 2:return A.b3(o.at(-1),r)}})
return A.b5($async$o9,r)},
vn(a){var s,r,q,p,o,n,m,l,k=B.a.V(a)
if(B.a.U(k,"Exception: "))k=B.a.V(B.a.az(k,11))
if(B.a.U(k,"Error: "))k=B.a.V(B.a.az(k,7))
s=A.aI("Table '([^']+)' does not exist",!1).bq(k)
if(s!=null){r=A.D(s.b[1])
q=t.N
return A.a7(["title","Table Not Found","error","Table '"+r+"' does not exist in the database catalog.","hint","Make sure you create the table first using 'CREATE TABLE "+r+" (...);' or check for spelling errors."],q,q)}p=A.aI("Table '([^']+)' already exists",!1).bq(k)
if(p!=null){r=A.D(p.b[1])
q=t.N
return A.a7(["title","Table Already Exists","error","A table named '"+r+"' already exists.","hint","Use 'DROP TABLE IF EXISTS "+r+";' before creating it, or choose a different table name."],q,q)}o=A.aI("Column '([^']+)' (?:does not exist|not found)",!1).bq(k)
if(o!=null){r=t.N
return A.a7(["title","Column Not Found","error","Column '"+A.D(o.b[1])+"' was not found in the referenced table schema.","hint","Check the column name spelling or run 'DESCRIBE <table>;' to see available columns."],r,r)}n=A.aI("Column count mismatch\\. Expected (\\d+) values, found (\\d+)",!1).bq(k)
if(n!=null){r=n.b
q=A.D(r[1])
m=t.N
return A.a7(["title","Column Count Mismatch","error","The INSERT statement supplied "+A.D(r[2])+" values, but the target table schema expects "+q+" columns.","hint","Specify explicit columns: 'INSERT INTO table (col1, col2) VALUES (...)' or supply all "+q+" values."],m,m)}if(B.a.E(k,"Expected ")||B.a.E(k,"Unexpected token")||B.a.E(k,"Syntax error")||B.a.E(k,"[Token")){l=B.a.E(k,"] ")?B.a.az(k,B.a.ac(k,"] ")+2):k
r=t.N
return A.a7(["title","SQL Syntax Error","error",l,"hint","Verify SQL keywords, commas between column names, quotes around text literals ('value'), and closing parentheses."],r,r)}if(B.a.E(k.toLowerCase(),"type mismatch")||B.a.E(k.toLowerCase(),"cannot cast")||B.a.E(k.toLowerCase(),"incompatible")){r=t.N
return A.a7(["title","Data Type Mismatch","error",k,"hint","Ensure your values match the column data types (e.g. single quotes for VARCHAR/TEXT, numbers for INT/DOUBLE)."],r,r)}if(B.a.E(k.toLowerCase(),"duplicate key")||B.a.E(k.toLowerCase(),"primary key constraint")||B.a.E(k.toLowerCase(),"unique constraint")){r=t.N
return A.a7(["title","Unique Constraint Violation","error",k,"hint","Primary key and UNIQUE columns must have distinct values. Consider using 'INSERT OR REPLACE' or distinct IDs."],r,r)}r=t.N
return A.a7(["title","Query Execution Error","error",k,"hint","Review the SQL statement structure and ensure referenced tables, columns, and data types are valid."],r,r)},
oo:function oo(){},
ob:function ob(){},
oa:function oa(){},
pw(a){if(typeof dartPrint=="function"){dartPrint(a)
return}if(typeof console=="object"&&typeof console.log!="undefined"){console.log(a)
return}if(typeof print=="function"){print(a)
return}throw"Unable to print message: "+String(a)},
tL(){throw A.c(A.a_("new RawReceivePort"))},
pZ(a,b){var s=null,r=new A.fo(new A.ad($.V,b.i("ad<0>")),b.i("fo<0>")),q=A.tL()},
uU(a,b,c){if(c>=1)return a.$1(b)
return a.$0()},
uV(a,b,c,d){if(d>=2)return a.$2(b,c)
if(d===1)return a.$1(b)
return a.$0()},
w_(a,b){var s,r
if(b==null)return new a()
if(b instanceof Array)switch(b.length){case 0:return new a()
case 1:return new a(b[0])
case 2:return new a(b[0],b[1])
case 3:return new a(b[0],b[1],b[2])
case 4:return new a(b[0],b[1],b[2],b[3])}s=[null]
B.b.X(s,b)
r=a.bind.apply(a,s)
String(r)
return new r()}},B={}
var w=[A,J,B]
var $={}
A.oT.prototype={}
J.hf.prototype={
aw(a,b){return a===b},
gY(a){return A.hC(a)},
l(a){return"Instance of '"+A.eS(a)+"'"},
gak(a){return A.d2(A.pj(this))}}
J.ey.prototype={
l(a){return String(a)},
gY(a){return a?519018:218159},
gak(a){return A.d2(t.y)},
$iac:1,
$iQ:1}
J.eA.prototype={
aw(a,b){return null==b},
l(a){return"null"},
gY(a){return 0},
$iac:1,
$iaE:1}
J.ap.prototype={$iam:1}
J.ch.prototype={
gY(a){return 0},
l(a){return String(a)}}
J.hB.prototype={}
J.cq.prototype={}
J.bf.prototype={
l(a){var s=a[$.rl()]
if(s==null)s=a[$.os()]
if(s==null)return this.fN(a)
return"JavaScript function for "+J.x(s)}}
J.dx.prototype={
gY(a){return 0},
l(a){return String(a)}}
J.dy.prototype={
gY(a){return 0},
l(a){return String(a)}}
J.C.prototype={
T(a,b){a.$flags&1&&A.i(a,29)
a.push(b)},
aN(a,b){a.$flags&1&&A.i(a,"removeAt",1)
if(b<0||b>=a.length)throw A.c(A.mH(b,null))
return a.splice(b,1)[0]},
dB(a,b,c){a.$flags&1&&A.i(a,"insert",2)
if(b<0||b>a.length)throw A.c(A.mH(b,null))
a.splice(b,0,c)},
S(a,b){var s
a.$flags&1&&A.i(a,"remove",1)
for(s=0;s<a.length;++s)if(J.az(a[s],b)){a.splice(s,1)
return!0}return!1},
fj(a,b,c){return new A.bV(a,b,A.z(a).i("@<1>").ar(c).i("bV<1,2>"))},
X(a,b){a.$flags&1&&A.i(a,"addAll",2)
this.fX(a,b)
return},
fX(a,b){var s,r=b.length
if(r===0)return
if(a===b)throw A.c(A.aA(a))
for(s=0;s<r;++s)a.push(b[s])},
v(a){a.$flags&1&&A.i(a,"clear","clear")
a.length=0},
bc(a,b,c){return new A.h(a,b,A.z(a).i("@<1>").ar(c).i("h<1,2>"))},
R(a,b){var s,r=A.a9(a.length,"",!1,t.N)
for(s=0;s<a.length;++s)r[s]=A.D(a[s])
return r.join(b)},
iF(a,b,c){var s,r,q=a.length
for(s=b,r=0;r<q;++r){s=c.$2(s,a[r])
if(a.length!==q)throw A.c(A.aA(a))}return s},
iG(a,b,c){return this.iF(a,b,c,t.z)},
iE(a,b,c){var s,r,q,p=a.length
for(s=0;s<p;++s){r=a[s]
if(b.$1(r))return r
if(a.length!==p)throw A.c(A.aA(a))}q=c.$0()
return q},
an(a,b){return a[b]},
bk(a,b,c){if(b<0||b>a.length)throw A.c(A.ax(b,0,a.length,"start",null))
if(c==null)c=a.length
else if(c<b||c>a.length)throw A.c(A.ax(c,b,a.length,"end",null))
if(b===c)return A.a([],A.z(a))
return A.a(a.slice(b,c),A.z(a))},
ad(a,b){return this.bk(a,b,null)},
gH(a){if(a.length>0)return a[0]
throw A.c(A.bX())},
gW(a){var s=a.length
if(s>0)return a[s-1]
throw A.c(A.bX())},
aF(a,b,c,d,e){var s,r,q,p
a.$flags&2&&A.i(a,5)
A.c2(b,c,a.length)
s=c-b
if(s===0)return
A.eU(e,"skipCount")
r=d
q=J.X(r)
if(e+s>q.gt(r))throw A.c(A.q_())
if(e<b)for(p=s-1;p>=0;--p)a[b+p]=q.h(r,e+p)
else for(p=0;p<s;++p)a[b+p]=q.h(r,e+p)},
a8(a,b,c,d){return this.aF(a,b,c,d,0)},
bC(a,b,c,d){var s
a.$flags&2&&A.i(a,"fillRange")
A.c2(b,c,a.length)
for(s=b;s<c;++s)a[s]=d},
b2(a,b){var s,r=a.length
for(s=0;s<r;++s){if(b.$1(a[s]))return!0
if(a.length!==r)throw A.c(A.aA(a))}return!1},
cr(a,b){var s,r=a.length
for(s=0;s<r;++s){if(!b.$1(a[s]))return!1
if(a.length!==r)throw A.c(A.aA(a))}return!0},
aq(a,b){var s,r,q,p,o
a.$flags&2&&A.i(a,"sort")
s=a.length
if(s<2)return
if(b==null)b=J.v8()
if(s===2){r=a[0]
q=a[1]
if(b.$2(r,q)>0){a[0]=q
a[1]=r}return}p=0
if(A.z(a).c.b(null))for(o=0;o<a.length;++o)if(a[o]===void 0){a[o]=null;++p}a.sort(A.fN(b,2))
if(p>0)this.i8(a,p)},
dS(a){return this.aq(a,null)},
i8(a,b){var s,r=a.length
for(;s=r-1,r>0;r=s)if(a[s]===null){a[s]=void 0;--b
if(b===0)break}},
fM(a,b){var s,r,q
a.$flags&2&&A.i(a,"shuffle")
s=a.length
while(s>1){r=b.cA(s);--s
q=a[s]
a[s]=a[r]
a[r]=q}},
ac(a,b){var s,r=a.length
if(0>=r)return-1
for(s=0;s<r;++s)if(J.az(a[s],b))return s
return-1},
E(a,b){var s
for(s=0;s<a.length;++s)if(J.az(a[s],b))return!0
return!1},
ga9(a){return a.length===0},
gaa(a){return a.length!==0},
l(a){return A.oQ(a,"[","]")},
aS(a,b){var s=A.a(a.slice(0),A.z(a))
return s},
aO(a){return this.aS(a,!0)},
gJ(a){return new J.be(a,a.length,A.z(a).i("be<1>"))},
gY(a){return A.hC(a)},
gt(a){return a.length},
h(a,b){if(!(b>=0&&b<a.length))throw A.c(A.od(a,b))
return a[b]},
k(a,b,c){a.$flags&2&&A.i(a)
if(!(b>=0&&b<a.length))throw A.c(A.od(a,b))
a[b]=c},
c1(a,b){var s
if(0>=a.length)return-1
for(s=0;s<a.length;++s)if(b.$1(a[s]))return s
return-1},
$iaQ:1,
$iJ:1,
$it:1,
cu(a,b){return this.gH(a).$1(b)}}
J.hj.prototype={
jc(a){var s,r,q
if(!Array.isArray(a))return null
s=a.$flags|0
if((s&4)!==0)r="const, "
else if((s&2)!==0)r="unmodifiable, "
else r=(s&1)!==0?"fixed, ":""
q="Instance of '"+A.eS(a)+"'"
if(r==="")return q
return q+" ("+r+"length: "+a.length+")"}}
J.l2.prototype={}
J.be.prototype={
gD(){var s=this.d
return s==null?this.$ti.c.a(s):s},
p(){var s,r=this,q=r.a,p=q.length
if(r.b!==p)throw A.c(A.n(q))
s=r.c
if(s>=p){r.d=null
return!1}r.d=q[s]
r.c=s+1
return!0},
$ia2:1}
J.cI.prototype={
A(a,b){var s
if(a<b)return-1
else if(a>b)return 1
else if(a===b){if(a===0){s=this.gcz(b)
if(this.gcz(a)===s)return 0
if(this.gcz(a))return-1
return 1}return 0}else if(isNaN(a)){if(isNaN(b))return 0
return 1}else return-1},
gcz(a){return a===0?1/a<0:a<0},
bd(a){var s
if(a>=-2147483648&&a<=2147483647)return a|0
if(isFinite(a)){s=a<0?Math.ceil(a):Math.floor(a)
return s+0}throw A.c(A.a_(""+a+".toInt()"))},
iu(a){var s,r
if(a>=0){if(a<=2147483647){s=a|0
return a===s?s:s+1}}else if(a>=-2147483648)return a|0
r=Math.ceil(a)
if(isFinite(r))return r
throw A.c(A.a_(""+a+".ceil()"))},
dz(a){var s,r
if(a>=0){if(a<=2147483647)return a|0}else if(a>=-2147483648){s=a|0
return a===s?s:s-1}r=Math.floor(a)
if(isFinite(r))return r
throw A.c(A.a_(""+a+".floor()"))},
ft(a){if(a>0){if(a!==1/0)return Math.round(a)}else if(a>-1/0)return 0-Math.round(0-a)
throw A.c(A.a_(""+a+".round()"))},
du(a,b,c){if(B.c.A(b,c)>0)throw A.c(A.vI(b))
if(this.A(a,b)<0)return b
if(this.A(a,c)>0)return c
return a},
fz(a,b){var s
if(b>20)throw A.c(A.ax(b,0,20,"fractionDigits",null))
s=a.toFixed(b)
if(a===0&&this.gcz(a))return"-"+s
return s},
fw(a,b){var s,r,q,p
if(b<2||b>36)throw A.c(A.ax(b,2,36,"radix",null))
s=a.toString(b)
if(s.charCodeAt(s.length-1)!==41)return s
r=/^([\da-z]+)(?:\.([\da-z]+))?\(e\+(\d+)\)$/.exec(s)
if(r==null)A.al(A.a_("Unexpected toString result: "+s))
s=r[1]
q=+r[3]
p=r[2]
if(p!=null){s+=p
q-=p.length}return s+B.a.P("0",q)},
l(a){if(a===0&&1/a<0)return"-0.0"
else return""+a},
gY(a){var s,r,q,p,o=a|0
if(a===o)return o&536870911
s=Math.abs(a)
r=Math.log(s)/0.6931471805599453|0
q=Math.pow(2,r)
p=s<1?s/q:q/s
return((p*9007199254740992|0)+(p*3542243181176521|0))*599197+r*1259&536870911},
a7(a,b){var s=a%b
if(s===0)return 0
if(s>0)return s
if(b<0)return s-b
else return s+b},
b_(a,b){if((a|0)===a)if(b>=1||b<-1)return a/b|0
return this.f0(a,b)},
a3(a,b){return(a|0)===a?a/b|0:this.f0(a,b)},
f0(a,b){var s=a/b
if(s>=-2147483648&&s<=2147483647)return s|0
if(s>0){if(s!==1/0)return Math.floor(s)}else if(s>-1/0)return Math.ceil(s)
throw A.c(A.a_("Result of truncating division is "+A.D(s)+": "+A.D(a)+" ~/ "+b))},
f_(a,b){return b>31?0:a<<b>>>0},
bV(a,b){var s
if(a>0)s=this.ik(a,b)
else{s=b>31?31:b
s=a>>s>>>0}return s},
ik(a,b){return b>31?0:a>>>b},
cM(a,b){return a<b},
gak(a){return A.d2(t.di)},
$iW:1}
J.ez.prototype={
gak(a){return A.d2(t.S)},
$iac:1,
$il:1}
J.hk.prototype={
gak(a){return A.d2(t.i)},
$iac:1}
J.cg.prototype={
f6(a,b){return new A.id(b,a,0)},
dH(a,b,c){var s,r,q=null
if(c<0||c>b.length)throw A.c(A.ax(c,0,b.length,q,q))
s=a.length
if(c+s>b.length)return q
for(r=0;r<s;++r)if(b.charCodeAt(c+r)!==a.charCodeAt(r))return q
return new A.dQ(c,a)},
B(a,b){var s=b.length,r=a.length
if(s>r)return!1
return b===this.az(a,r-s)},
cQ(a,b){var s
if(typeof b=="string")return A.a(a.split(b),t.s)
else{if(b instanceof A.dw){s=b.e
s=!(s==null?b.e=b.h5():s)}else s=!1
if(s)return A.a(a.split(b.b),t.s)
else return this.h8(a,b)}},
h8(a,b){var s,r,q,p,o,n,m=A.a([],t.s)
for(s=J.pC(b,a),s=s.gJ(s),r=0,q=1;s.p();){p=s.gD()
o=p.gcR()
n=p.gcq()
q=n-o
if(q===0&&r===o)continue
m.push(this.O(a,r,o))
r=n}if(r<a.length||q>0)m.push(this.az(a,r))
return m},
c6(a,b,c){var s,r=a.length
if(c>r)throw A.c(A.ax(c,0,r,null,null))
if(typeof b=="string"){s=c+b.length
if(s>r)return!1
return b===a.substring(c,s)}return J.rU(b,a,c)!=null},
U(a,b){return this.c6(a,b,0)},
O(a,b,c){return a.substring(b,A.c2(b,c,a.length))},
az(a,b){return this.O(a,b,null)},
V(a){var s,r,q,p=a.trim(),o=p.length
if(o===0)return p
if(p.charCodeAt(0)===133){s=J.ts(p,1)
if(s===o)return""}else s=0
r=o-1
q=p.charCodeAt(r)===133?J.tt(p,r):o
if(s===0&&q===o)return p
return p.substring(s,q)},
P(a,b){var s,r
if(0>=b)return""
if(b===1||a.length===0)return a
if(b!==b>>>0)throw A.c(B.cv)
for(s=a,r="";;){if((b&1)===1)r=s+r
b=b>>>1
if(b===0)break
s+=s}return r},
a1(a,b,c){var s=b-a.length
if(s<=0)return a
return this.P(c,s)+a},
iZ(a,b,c){var s=b-a.length
if(s<=0)return a
return a+this.P(c,s)},
fl(a,b,c){var s,r,q,p
if(c<0||c>a.length)throw A.c(A.ax(c,0,a.length,null,null))
if(typeof b=="string")return a.indexOf(b,c)
if(b instanceof A.dw){s=b.eh(a,c)
return s==null?-1:s.b.index}for(r=a.length,q=J.e0(b),p=c;p<=r;++p)if(q.dH(b,a,p)!=null)return p
return-1},
ac(a,b){return this.fl(a,b,0)},
iR(a,b){var s,r=a.length
for(s=r;s>=0;--s){if(s>r)A.al(A.ax(s,0,r,null,null))
if(b.eg(a,s)!=null)return s}return-1},
E(a,b){return A.wm(a,b,0)},
gaa(a){return a.length!==0},
A(a,b){var s
if(a===b)s=0
else s=a<b?-1:1
return s},
l(a){return a},
gY(a){var s,r,q
for(s=a.length,r=0,q=0;q<s;++q){r=r+a.charCodeAt(q)&536870911
r=r+((r&524287)<<10)&536870911
r^=r>>6}r=r+((r&67108863)<<3)&536870911
r^=r>>11
return r+((r&16383)<<15)&536870911},
gak(a){return A.d2(t.N)},
gt(a){return a.length},
h(a,b){if(!(b>=0&&b<a.length))throw A.c(A.od(a,b))
return a[b]},
$iaQ:1,
$iac:1,
$ie:1}
A.nn.prototype={
T(a,b){var s,r=this,q=b.length
if(q===0)return
s=r.a+q
if(r.b.length<s)r.eu(s)
B.j.a8(r.b,r.a,s,b)
r.a=s},
iq(a){var s=this,r=s.b,q=s.a
if(r.length===q)s.eu(q)
r=s.b
q=s.a
r.$flags&2&&A.i(r)
r[q]=a
s.a=q+1},
eu(a){var s,r,q,p=a*2
if(p<1024)p=1024
else{s=p-1
s|=B.c.bV(s,1)
s|=s>>>2
s|=s>>>4
s|=s>>>8
p=((s|s>>>16)>>>0)+1}r=new Uint8Array(p)
q=this.b
B.j.a8(r,0,q.length,q)
this.b=r},
j8(){var s,r=this
if(r.a===0)return $.ov()
s=J.bm(B.j.gai(r.b),r.b.byteOffset,r.a)
r.a=0
r.b=$.ov()
return s},
gt(a){return this.a},
gaa(a){return this.a!==0}}
A.cJ.prototype={
l(a){return"LateInitializationError: "+this.a}}
A.da.prototype={
gt(a){return this.a.length},
h(a,b){return this.a.charCodeAt(b)}}
A.mN.prototype={}
A.J.prototype={}
A.u.prototype={
gJ(a){var s=this
return new A.cL(s,s.gt(s),A.E(s).i("cL<u.E>"))},
ga9(a){return this.gt(this)===0},
gH(a){if(this.gt(this)===0)throw A.c(A.bX())
return this.an(0,0)},
R(a,b){var s,r,q,p=this,o=p.gt(p)
if(b.length!==0){if(o===0)return""
s=A.D(p.an(0,0))
if(o!==p.gt(p))throw A.c(A.aA(p))
for(r=s,q=1;q<o;++q){r=r+b+A.D(p.an(0,q))
if(o!==p.gt(p))throw A.c(A.aA(p))}return r.charCodeAt(0)==0?r:r}else{for(q=0,r="";q<o;++q){r+=A.D(p.an(0,q))
if(o!==p.gt(p))throw A.c(A.aA(p))}return r.charCodeAt(0)==0?r:r}},
dE(a){return this.R(0,"")},
bc(a,b,c){return new A.h(this,b,A.E(this).i("@<u.E>").ar(c).i("h<1,2>"))},
aS(a,b){var s=A.r(this,A.E(this).i("u.E"))
return s},
aO(a){return this.aS(0,!0)},
ja(a){var s,r=this,q=A.oW(A.E(r).i("u.E"))
for(s=0;s<r.gt(r);++s)q.T(0,r.an(0,s))
return q}}
A.fe.prototype={
gha(){var s=J.O(this.a),r=this.c
if(r==null||r>s)return s
return r},
gim(){var s=J.O(this.a),r=this.b
if(r>s)return s
return r},
gt(a){var s,r=J.O(this.a),q=this.b
if(q>=r)return 0
s=this.c
if(s==null||s>=r)return r-q
return s-q},
an(a,b){var s=this,r=s.gim()+b
if(b<0||r>=s.gha())throw A.c(A.oP(b,s.gt(0),s,"index"))
return J.pE(s.a,r)},
aS(a,b){var s,r,q,p=this,o=p.b,n=p.a,m=J.X(n),l=m.gt(n),k=p.c
if(k!=null&&k<l)l=k
s=l-o
if(s<=0){n=p.$ti.c
return b?J.oR(0,n):J.q1(0,n)}r=A.a9(s,m.an(n,o),b,p.$ti.c)
for(q=1;q<s;++q){r[q]=m.an(n,o+q)
if(m.gt(n)<l)throw A.c(A.aA(p))}return r},
aO(a){return this.aS(0,!0)}}
A.cL.prototype={
gD(){var s=this.d
return s==null?this.$ti.c.a(s):s},
p(){var s,r=this,q=r.a,p=J.X(q),o=p.gt(q)
if(r.b!==o)throw A.c(A.aA(q))
s=r.c
if(s>=o){r.d=null
return!1}r.d=p.an(q,s);++r.c
return!0},
$ia2:1}
A.cM.prototype={
gJ(a){return new A.eE(J.as(this.a),this.b,A.E(this).i("eE<1,2>"))},
gt(a){return J.O(this.a)},
ga9(a){return J.pF(this.a)},
gH(a){return this.b.$1(J.e3(this.a))}}
A.ek.prototype={$iJ:1}
A.eE.prototype={
p(){var s=this,r=s.b
if(r.p()){s.a=s.c.$1(r.gD())
return!0}s.a=null
return!1},
gD(){var s=this.a
return s==null?this.$ti.y[1].a(s):s},
$ia2:1}
A.h.prototype={
gt(a){return J.O(this.a)},
an(a,b){return this.b.$1(J.pE(this.a,b))}}
A.aJ.prototype={
gJ(a){return new A.fl(J.as(this.a),this.b,this.$ti.i("fl<1>"))}}
A.fl.prototype={
p(){var s,r
for(s=this.a,r=this.b;s.p();)if(r.$1(s.gD()))return!0
return!1},
gD(){return this.a.gD()},
$ia2:1}
A.bV.prototype={
gJ(a){return new A.eo(J.as(this.a),this.b,B.co,this.$ti.i("eo<1,2>"))}}
A.eo.prototype={
gD(){var s=this.d
return s==null?this.$ti.y[1].a(s):s},
p(){var s,r,q=this,p=q.c
if(p==null)return!1
for(s=q.a,r=q.b;!p.p();){q.d=null
if(s.p()){q.c=null
p=J.as(r.$1(s.gD()))
q.c=p}else return!1}q.d=q.c.gD()
return!0},
$ia2:1}
A.em.prototype={
p(){return!1},
gD(){throw A.c(A.bX())},
$ia2:1}
A.es.prototype={
st(a,b){throw A.c(A.a_("Cannot change the length of a fixed-length list"))},
T(a,b){throw A.c(A.a_("Cannot add to a fixed-length list"))},
S(a,b){throw A.c(A.a_("Cannot remove from a fixed-length list"))}}
A.hQ.prototype={
k(a,b,c){throw A.c(A.a_("Cannot modify an unmodifiable list"))},
st(a,b){throw A.c(A.a_("Cannot change the length of an unmodifiable list"))},
T(a,b){throw A.c(A.a_("Cannot add to an unmodifiable list"))},
S(a,b){throw A.c(A.a_("Cannot remove from an unmodifiable list"))},
aq(a,b){throw A.c(A.a_("Cannot modify an unmodifiable list"))},
aF(a,b,c,d,e){throw A.c(A.a_("Cannot modify an unmodifiable list"))},
a8(a,b,c,d){return this.aF(0,b,c,d,0)}}
A.dT.prototype={}
A.eY.prototype={
gt(a){return J.O(this.a)},
an(a,b){var s=this.a,r=J.X(s)
return r.an(s,r.gt(s)-1-b)}}
A.hL.prototype={
gY(a){var s=this._hashCode
if(s!=null)return s
s=664597*B.a.gY(this.a)&536870911
this._hashCode=s
return s},
l(a){return'Symbol("'+this.a+'")'},
aw(a,b){if(b==null)return!1
return b instanceof A.hL&&this.a===b.a}}
A.ia.prototype={$r:"+condFn,thenFn(1,2)",$s:1}
A.ec.prototype={
ga9(a){return this.gt(this)===0},
gaa(a){return this.gt(this)!==0},
l(a){return A.oX(this)},
k(a,b,c){A.oD()},
I(a,b){A.oD()},
S(a,b){A.oD()},
gbZ(){return new A.ct(this.iz(),A.E(this).i("ct<aj<1,2>>"))},
iz(){var s=this
return function(){var r=0,q=1,p=[],o,n,m
return function $async$gbZ(a,b,c){if(b===1){p.push(c)
r=q}for(;;)switch(r){case 0:o=s.gZ(),o=o.gJ(o),n=A.E(s).i("aj<1,2>")
case 2:if(!o.p()){r=3
break}m=o.gD()
r=4
return a.b=new A.aj(m,s.h(0,m),n),1
case 4:r=2
break
case 3:return 0
case 1:return a.c=p.at(-1),3}}}},
$iw:1}
A.ee.prototype={
gt(a){return this.b.length},
gez(){var s=this.$keys
if(s==null){s=Object.keys(this.a)
this.$keys=s}return s},
F(a){if(typeof a!="string")return!1
if("__proto__"===a)return!1
return this.a.hasOwnProperty(a)},
h(a,b){if(!this.F(b))return null
return this.b[this.a[b]]},
a0(a,b){var s,r,q=this.gez(),p=this.b
for(s=q.length,r=0;r<s;++r)b.$2(q[r],p[r])},
gZ(){return new A.cV(this.gez(),this.$ti.i("cV<1>"))},
gaP(){return new A.cV(this.b,this.$ti.i("cV<2>"))}}
A.cV.prototype={
gt(a){return this.a.length},
ga9(a){return 0===this.a.length},
gaa(a){return 0!==this.a.length},
gJ(a){var s=this.a
return new A.cW(s,s.length,this.$ti.i("cW<1>"))}}
A.cW.prototype={
gD(){var s=this.d
return s==null?this.$ti.c.a(s):s},
p(){var s=this,r=s.c
if(r>=s.b){s.d=null
return!1}s.d=s.a[r]
s.c=r+1
return!0},
$ia2:1}
A.ed.prototype={
T(a,b){A.t3()}}
A.bR.prototype={
gt(a){return this.b},
ga9(a){return this.b===0},
gaa(a){return this.b!==0},
gJ(a){var s,r=this,q=r.$keys
if(q==null){q=Object.keys(r.a)
r.$keys=q}s=q
return new A.cW(s,s.length,r.$ti.i("cW<1>"))},
E(a,b){if(typeof b!="string")return!1
if("__proto__"===b)return!1
return this.a.hasOwnProperty(b)}}
A.ml.prototype={
$0(){return B.h.dz(1000*this.a.now())},
$S:15}
A.f1.prototype={}
A.n7.prototype={
aZ(a){var s,r,q=this,p=new RegExp(q.a).exec(a)
if(p==null)return null
s=Object.create(null)
r=q.b
if(r!==-1)s.arguments=p[r+1]
r=q.c
if(r!==-1)s.argumentsExpr=p[r+1]
r=q.d
if(r!==-1)s.expr=p[r+1]
r=q.e
if(r!==-1)s.method=p[r+1]
r=q.f
if(r!==-1)s.receiver=p[r+1]
return s}}
A.eM.prototype={
l(a){return"Null check operator used on a null value"}}
A.hl.prototype={
l(a){var s,r=this,q="NoSuchMethodError: method not found: '",p=r.b
if(p==null)return"NoSuchMethodError: "+r.a
s=r.c
if(s==null)return q+p+"' ("+r.a+")"
return q+p+"' on '"+s+"' ("+r.a+")"}}
A.hP.prototype={
l(a){var s=this.a
return s.length===0?"Error":"Error: "+s}}
A.lZ.prototype={
l(a){return"Throw of null ('"+(this.a===null?"null":"undefined")+"' from JavaScript)"}}
A.en.prototype={}
A.fC.prototype={
l(a){var s,r=this.b
if(r!=null)return r
r=this.a
s=r!==null&&typeof r==="object"?r.stack:null
return this.b=s==null?"":s},
$iaX:1}
A.cz.prototype={
l(a){var s=this.constructor,r=s==null?null:s.name
return"Closure '"+A.rk(r==null?"unknown":r)+"'"},
gjg(){return this},
$C:"$1",
$R:1,
$D:null}
A.iL.prototype={$C:"$0",$R:0}
A.iM.prototype={$C:"$2",$R:2}
A.n5.prototype={}
A.mP.prototype={
l(a){var s=this.$static_name
if(s==null)return"Closure of unknown static method"
return"Closure '"+A.rk(s)+"'"}}
A.e8.prototype={
aw(a,b){if(b==null)return!1
if(this===b)return!0
if(!(b instanceof A.e8))return!1
return this.$_target===b.$_target&&this.a===b.a},
gY(a){return(A.rf(this.a)^A.hC(this.$_target))>>>0},
l(a){return"Closure '"+this.$_name+"' of "+("Instance of '"+A.eS(this.a)+"'")}}
A.hH.prototype={
l(a){return"RuntimeError: "+this.a}}
A.bZ.prototype={
gt(a){return this.a},
ga9(a){return this.a===0},
gaa(a){return this.a!==0},
gZ(){return new A.aB(this,A.E(this).i("aB<1>"))},
gaP(){return new A.b1(this,A.E(this).i("b1<2>"))},
gbZ(){return new A.an(this,A.E(this).i("an<1,2>"))},
F(a){var s,r
if(typeof a=="string"){s=this.b
if(s==null)return!1
return s[a]!=null}else if(typeof a=="number"&&(a&0x3fffffff)===a){r=this.c
if(r==null)return!1
return r[a]!=null}else return this.iL(a)},
iL(a){var s=this.d
if(s==null)return!1
return this.cw(s[this.cv(a)],a)>=0},
X(a,b){b.a0(0,new A.lN(this))},
h(a,b){var s,r,q,p,o=null
if(typeof b=="string"){s=this.b
if(s==null)return o
r=s[b]
q=r==null?o:r.b
return q}else if(typeof b=="number"&&(b&0x3fffffff)===b){p=this.c
if(p==null)return o
r=p[b]
q=r==null?o:r.b
return q}else return this.iM(b)},
iM(a){var s,r,q=this.d
if(q==null)return null
s=q[this.cv(a)]
r=this.cw(s,a)
if(r<0)return null
return s[r].b},
k(a,b,c){var s,r,q=this
if(typeof b=="string"){s=q.b
q.dX(s==null?q.b=q.de():s,b,c)}else if(typeof b=="number"&&(b&0x3fffffff)===b){r=q.c
q.dX(r==null?q.c=q.de():r,b,c)}else q.iO(b,c)},
iO(a,b){var s,r,q,p=this,o=p.d
if(o==null)o=p.d=p.de()
s=p.cv(a)
r=o[s]
if(r==null)o[s]=[p.df(a,b)]
else{q=p.cw(r,a)
if(q>=0)r[q].b=b
else r.push(p.df(a,b))}},
I(a,b){var s,r,q=this
if(q.F(a)){s=q.h(0,a)
return s==null?A.E(q).y[1].a(s):s}r=b.$0()
q.k(0,a,r)
return r},
S(a,b){var s=this
if(typeof b=="string")return s.dV(s.b,b)
else if(typeof b=="number"&&(b&0x3fffffff)===b)return s.dV(s.c,b)
else return s.iN(b)},
iN(a){var s,r,q,p,o=this,n=o.d
if(n==null)return null
s=o.cv(a)
r=n[s]
q=o.cw(r,a)
if(q<0)return null
p=r.splice(q,1)[0]
o.dW(p)
if(r.length===0)delete n[s]
return p.b},
v(a){var s=this
if(s.a>0){s.b=s.c=s.d=s.e=s.f=null
s.a=0
s.dd()}},
a0(a,b){var s=this,r=s.e,q=s.r
while(r!=null){b.$2(r.a,r.b)
if(q!==s.r)throw A.c(A.aA(s))
r=r.c}},
dX(a,b,c){var s=a[b]
if(s==null)a[b]=this.df(b,c)
else s.b=c},
dV(a,b){var s
if(a==null)return null
s=a[b]
if(s==null)return null
this.dW(s)
delete a[b]
return s.b},
dd(){this.r=this.r+1&1073741823},
df(a,b){var s,r=this,q=new A.lR(a,b)
if(r.e==null)r.e=r.f=q
else{s=r.f
s.toString
q.d=s
r.f=s.c=q}++r.a
r.dd()
return q},
dW(a){var s=this,r=a.d,q=a.c
if(r==null)s.e=q
else r.c=q
if(q==null)s.f=r
else q.d=r;--s.a
s.dd()},
cv(a){return J.by(a)&1073741823},
cw(a,b){var s,r
if(a==null)return-1
s=a.length
for(r=0;r<s;++r)if(J.az(a[r].a,b))return r
return-1},
l(a){return A.oX(this)},
de(){var s=Object.create(null)
s["<non-identifier-key>"]=s
delete s["<non-identifier-key>"]
return s}}
A.lN.prototype={
$2(a,b){this.a.k(0,a,b)},
$S(){return A.E(this.a).i("~(1,2)")}}
A.lR.prototype={}
A.aB.prototype={
gt(a){return this.a.a},
ga9(a){return this.a.a===0},
gJ(a){var s=this.a
return new A.aL(s,s.r,s.e,this.$ti.i("aL<1>"))},
E(a,b){return this.a.F(b)}}
A.aL.prototype={
gD(){return this.d},
p(){var s,r=this,q=r.a
if(r.b!==q.r)throw A.c(A.aA(q))
s=r.c
if(s==null){r.d=null
return!1}else{r.d=s.a
r.c=s.c
return!0}},
$ia2:1}
A.b1.prototype={
gt(a){return this.a.a},
ga9(a){return this.a.a===0},
gJ(a){var s=this.a
return new A.ao(s,s.r,s.e,this.$ti.i("ao<1>"))}}
A.ao.prototype={
gD(){return this.d},
p(){var s,r=this,q=r.a
if(r.b!==q.r)throw A.c(A.aA(q))
s=r.c
if(s==null){r.d=null
return!1}else{r.d=s.b
r.c=s.c
return!0}},
$ia2:1}
A.an.prototype={
gt(a){return this.a.a},
ga9(a){return this.a.a===0},
gJ(a){var s=this.a
return new A.eD(s,s.r,s.e,this.$ti.i("eD<1,2>"))}}
A.eD.prototype={
gD(){var s=this.d
s.toString
return s},
p(){var s,r=this,q=r.a
if(r.b!==q.r)throw A.c(A.aA(q))
s=r.c
if(s==null){r.d=null
return!1}else{r.d=new A.aj(s.a,s.b,r.$ti.i("aj<1,2>"))
r.c=s.c
return!0}},
$ia2:1}
A.oj.prototype={
$1(a){return this.a(a)},
$S:44}
A.ok.prototype={
$2(a,b){return this.a(a,b)},
$S:74}
A.ol.prototype={
$1(a){return this.a(a)},
$S:54}
A.fA.prototype={
l(a){return this.f2(!1)},
f2(a){var s,r,q,p,o,n=this.hF(),m=this.ep(),l=(a?"Record ":"")+"("
for(s=n.length,r="",q=0;q<s;++q,r=", "){l+=r
p=n[q]
if(typeof p=="string")l=l+p+": "
o=m[q]
l=a?l+A.qg(o):l+A.D(o)}l+=")"
return l.charCodeAt(0)==0?l:l},
hF(){var s,r=this.$s
while($.nN.length<=r)$.nN.push(null)
s=$.nN[r]
if(s==null){s=this.h4()
$.nN[r]=s}return s},
h4(){var s,r,q,p=this.$r,o=p.indexOf("("),n=p.substring(1,o),m=p.substring(o),l=m==="()"?0:m.replace(/[^,]/g,"").length+1,k=t.C,j=J.dv(l,k)
for(s=0;s<l;++s)j[s]=s
if(n!==""){r=n.split(",")
s=r.length
for(q=l;s>0;){--q;--s
j[q]=r[s]}}return A.q8(j,k)}}
A.i9.prototype={
ep(){return[this.a,this.b]},
aw(a,b){if(b==null)return!1
return b instanceof A.i9&&this.$s===b.$s&&J.az(this.a,b.a)&&J.az(this.b,b.b)},
gY(a){return A.q9(this.$s,this.a,this.b,B.V)}}
A.dw.prototype={
l(a){return"RegExp/"+this.a+"/"+this.b.flags},
geB(){var s=this,r=s.c
if(r!=null)return r
r=s.b
return s.c=A.oS(s.a,r.multiline,!r.ignoreCase,r.unicode,r.dotAll,"g")},
ghU(){var s=this,r=s.d
if(r!=null)return r
r=s.b
return s.d=A.oS(s.a,r.multiline,!r.ignoreCase,r.unicode,r.dotAll,"y")},
h5(){var s,r=this.a
if(!B.a.E(r,"("))return!1
s=this.b.unicode?"u":""
return new RegExp("(?:)|"+r,s).exec("").length>1},
bq(a){var s=this.b.exec(a)
if(s==null)return null
return new A.dW(s)},
f6(a,b){return new A.hV(this,b,0)},
eh(a,b){var s,r=this.geB()
r.lastIndex=b
s=r.exec(a)
if(s==null)return null
return new A.dW(s)},
eg(a,b){var s,r=this.ghU()
r.lastIndex=b
s=r.exec(a)
if(s==null)return null
return new A.dW(s)},
dH(a,b,c){if(c<0||c>b.length)throw A.c(A.ax(c,0,b.length,null,null))
return this.eg(b,c)}}
A.dW.prototype={
gcR(){return this.b.index},
gcq(){var s=this.b
return s.index+s[0].length},
h(a,b){return this.b[b]},
$idz:1,
$ieV:1}
A.hV.prototype={
gJ(a){return new A.hW(this.a,this.b,this.c)}}
A.hW.prototype={
gD(){var s=this.d
return s==null?t.cz.a(s):s},
p(){var s,r,q,p,o,n,m=this,l=m.b
if(l==null)return!1
s=m.c
r=l.length
if(s<=r){q=m.a
p=q.eh(l,s)
if(p!=null){m.d=p
o=p.gcq()
if(p.b.index===o){s=!1
if(q.b.unicode){q=m.c
n=q+1
if(n<r){r=l.charCodeAt(q)
if(r>=55296&&r<=56319){s=l.charCodeAt(n)
s=s>=56320&&s<=57343}}}o=(s?o+1:o)+1}m.c=o
return!0}}m.b=m.d=null
return!1},
$ia2:1}
A.dQ.prototype={
gcq(){return this.a+this.c.length},
h(a,b){if(b!==0)throw A.c(A.mH(b,null))
return this.c},
$idz:1,
gcR(){return this.a}}
A.id.prototype={
gJ(a){return new A.ie(this.a,this.b,this.c)},
gH(a){var s=this.b,r=this.a.indexOf(s,this.c)
if(r>=0)return new A.dQ(r,s)
throw A.c(A.bX())}}
A.ie.prototype={
p(){var s,r,q=this,p=q.c,o=q.b,n=o.length,m=q.a,l=m.length
if(p+n>l){q.d=null
return!1}s=m.indexOf(o,p)
if(s<0){q.c=l+1
q.d=null
return!1}r=s+n
q.d=new A.dQ(s,o)
q.c=r===q.c?r+1:r
return!0},
gD(){var s=this.d
s.toString
return s},
$ia2:1}
A.nm.prototype={
eP(){var s=this.b
if(s===this)throw A.c(new A.cJ("Local '' has not been initialized."))
return s}}
A.dB.prototype={
gak(a){return B.cW},
ck(a,b,c){A.d_(a,b,c)
return c==null?new Uint8Array(a,b):new Uint8Array(a,b,c)},
fa(a){return this.ck(a,0,null)},
f9(a,b,c){A.d_(a,b,c)
return new Int32Array(a,b,c)},
f8(a,b,c){A.d_(a,b,c)
return new Float64Array(a,b,c)},
f7(a,b,c){var s
A.d_(a,b,c)
s=new DataView(a,b,c)
return s},
$iac:1}
A.eJ.prototype={
gai(a){if(((a.$flags|0)&2)!==0)return new A.nW(a.buffer)
else return a.buffer},
hM(a,b,c,d){var s=A.ax(b,0,c,d,null)
throw A.c(s)},
e3(a,b,c,d){if(b>>>0!==b||b>c)this.hM(a,b,c,d)}}
A.nW.prototype={
ck(a,b,c){var s=A.tA(this.a,b,c)
s.$flags=3
return s},
fa(a){return this.ck(0,0,null)},
f9(a,b,c){var s=A.tz(this.a,b,c)
s.$flags=3
return s},
f8(a,b,c){var s=A.ty(this.a,b,c)
s.$flags=3
return s},
f7(a,b,c){var s=A.tx(this.a,b,c)
s.$flags=3
return s}}
A.eG.prototype={
gak(a){return B.cX},
c2(a,b){throw A.c(A.a_("Int64 accessor not supported by dart2js."))},
hK(a,b,c){return a.getUint16(b,c)},
c4(a,b,c){throw A.c(A.a_("Int64 accessor not supported by dart2js."))},
ij(a,b,c,d){return a.setUint16(b,c,d)},
fL(a,b,c){throw A.c(A.a_("Uint64 accessor not supported by dart2js."))},
$iac:1}
A.dC.prototype={
gt(a){return a.length},
eZ(a,b,c,d,e){var s,r,q=a.length
this.e3(a,b,q,"start")
this.e3(a,c,q,"end")
if(b>c)throw A.c(A.ax(b,0,c,null,null))
s=c-b
if(e<0)throw A.c(A.bn(e,null))
r=d.length
if(r-e<s)throw A.c(A.fb("Not enough elements"))
if(e!==0||r!==s)d=d.subarray(e,e+s)
a.set(d,b)},
$iaQ:1,
$ibg:1}
A.cj.prototype={
h(a,b){A.c9(b,a,a.length)
return a[b]},
k(a,b,c){a.$flags&2&&A.i(a)
A.c9(b,a,a.length)
a[b]=c},
aF(a,b,c,d,e){a.$flags&2&&A.i(a,5)
if(t.d4.b(d)){this.eZ(a,b,c,d,e)
return}this.dT(a,b,c,d,e)},
a8(a,b,c,d){return this.aF(a,b,c,d,0)},
$iJ:1,
$it:1}
A.bh.prototype={
k(a,b,c){a.$flags&2&&A.i(a)
A.c9(b,a,a.length)
a[b]=c},
aF(a,b,c,d,e){a.$flags&2&&A.i(a,5)
if(t.eB.b(d)){this.eZ(a,b,c,d,e)
return}this.dT(a,b,c,d,e)},
a8(a,b,c,d){return this.aF(a,b,c,d,0)},
$iJ:1,
$it:1}
A.hn.prototype={
gak(a){return B.cY},
$iac:1}
A.eH.prototype={
gak(a){return B.cZ},
$iac:1}
A.ho.prototype={
gak(a){return B.d_},
h(a,b){A.c9(b,a,a.length)
return a[b]},
$iac:1}
A.eI.prototype={
gak(a){return B.d0},
h(a,b){A.c9(b,a,a.length)
return a[b]},
$iac:1}
A.hp.prototype={
gak(a){return B.d1},
h(a,b){A.c9(b,a,a.length)
return a[b]},
$iac:1}
A.hq.prototype={
gak(a){return B.d3},
h(a,b){A.c9(b,a,a.length)
return a[b]},
$iac:1}
A.hr.prototype={
gak(a){return B.d4},
h(a,b){A.c9(b,a,a.length)
return a[b]},
$iac:1}
A.eK.prototype={
gak(a){return B.d5},
gt(a){return a.length},
h(a,b){A.c9(b,a,a.length)
return a[b]},
$iac:1}
A.eL.prototype={
gak(a){return B.d6},
gt(a){return a.length},
h(a,b){A.c9(b,a,a.length)
return a[b]},
bk(a,b,c){return new Uint8Array(a.subarray(b,A.pg(b,c,a.length)))},
$iac:1,
$ibb:1}
A.fw.prototype={}
A.fx.prototype={}
A.fy.prototype={}
A.fz.prototype={}
A.bD.prototype={
i(a){return A.fH(v.typeUniverse,this,a)},
ar(a){return A.qH(v.typeUniverse,this,a)}}
A.i4.prototype={}
A.nU.prototype={
l(a){return A.bl(this.a,null)}}
A.i3.prototype={
l(a){return this.a}}
A.fD.prototype={$ic5:1}
A.nj.prototype={
$1(a){var s=this.a,r=s.a
s.a=null
r.$0()},
$S:33}
A.ni.prototype={
$1(a){var s,r
this.a.a=a
s=this.b
r=this.c
s.firstChild?s.removeChild(r):s.appendChild(r)},
$S:86}
A.nk.prototype={
$0(){this.a.$0()},
$S:11}
A.nl.prototype={
$0(){this.a.$0()},
$S:11}
A.ih.prototype={
fU(a,b){if(self.setTimeout!=null)self.setTimeout(A.fN(new A.nT(this,b),0),a)
else throw A.c(A.a_("`setTimeout()` not found."))},
fV(a,b){if(self.setTimeout!=null)self.setInterval(A.fN(new A.nS(this,a,Date.now(),b),0),a)
else throw A.c(A.a_("Periodic timer."))}}
A.nT.prototype={
$0(){this.a.c=1
this.b.$0()},
$S:2}
A.nS.prototype={
$0(){var s,r=this,q=r.a,p=q.c+1,o=r.b
if(o>0){s=Date.now()-r.c
if(s>(p+1)*o)p=B.c.b_(s,o)}q.c=p
r.d.$1(q)},
$S:11}
A.hX.prototype={
fc(a){var s,r=this
if(a==null)a=r.$ti.c.a(a)
if(!r.b)r.a.dZ(a)
else{s=r.a
if(r.$ti.i("b8<1>").b(a))s.e0(a)
else s.ca(a)}},
fd(a,b){var s=this.a
if(this.b)s.bl(new A.aK(a,b))
else s.c7(new A.aK(a,b))}}
A.o0.prototype={
$1(a){return this.a.$2(0,a)},
$S:73}
A.o1.prototype={
$2(a,b){this.a.$2(1,new A.en(a,b))},
$S:70}
A.oc.prototype={
$2(a,b){this.a(a,b)},
$S:69}
A.c8.prototype={
gD(){return this.b},
i9(a,b){var s,r,q
a=a
b=b
s=this.a
for(;;)try{r=s(this,a,b)
return r}catch(q){b=q
a=1}},
p(){var s,r,q,p,o=this,n=null,m=0
for(;;){s=o.d
if(s!=null)try{if(s.p()){o.b=s.gD()
return!0}else o.d=null}catch(r){n=r
m=1
o.d=null}q=o.i9(m,n)
if(1===q)return!0
if(0===q){o.b=null
p=o.e
if(p==null||p.length===0){o.a=A.qC
return!1}o.a=p.pop()
m=0
n=null
continue}if(2===q){m=0
n=null
continue}if(3===q){n=o.c
o.c=null
p=o.e
if(p==null||p.length===0){o.b=null
o.a=A.qC
throw n
return!1}o.a=p.pop()
m=1
continue}throw A.c(A.fb("sync*"))}return!1},
jj(a){var s,r,q=this
if(a instanceof A.ct){s=a.a()
r=q.e
if(r==null)r=q.e=[]
r.push(q.a)
q.a=s
return 2}else{q.d=J.as(a)
return 2}},
$ia2:1}
A.ct.prototype={
gJ(a){return new A.c8(this.a(),this.$ti.i("c8<1>"))}}
A.aK.prototype={
l(a){return A.D(this.a)},
$iah:1,
gbH(){return this.b}}
A.fp.prototype={
ghT(){return this.c<4},
fY(){if((this.c&4)!==0)return new A.cm("Cannot add new events after calling close")
return new A.cm("Cannot add new events while doing an addStream")},
T(a,b){if(!this.ghT())throw A.c(this.fY())
this.ig(b)},
$ifd:1}
A.fn.prototype={
ig(a){var s
for(s=this.d;!1;s=s.gji())s.jh(new A.i1())}}
A.jd.prototype={
$0(){var s,r,q,p,o,n,m,l=null
try{l=this.a.$0()}catch(q){s=A.aV(q)
r=A.bN(q)
p=s
o=r
n=A.pk(p,o)
if(n==null)p=new A.aK(p,o)
else p=n
this.b.bl(p)
return}p=this.b
o=l
if(p.$ti.i("b8<1>").b(o))A.nx(o,p,!0)
else{m=p.bU()
p.a=8
p.c=o
A.cT(p,m)}},
$S:2}
A.jf.prototype={
$2(a,b){var s=this,r=s.a,q=--r.b
if(r.a!=null){r.a=null
r.d=a
r.c=b
if(q===0||s.c)s.d.bl(new A.aK(a,b))}else if(q===0&&!s.c){q=r.d
q.toString
r=r.c
r.toString
s.d.bl(new A.aK(q,r))}},
$S:67}
A.je.prototype={
$1(a){var s,r,q,p,o,n,m=this,l=m.a,k=--l.b,j=l.a
if(j!=null){J.aY(j,m.b,a)
if(J.az(k,0)){l=m.d
s=A.a([],l.i("C<0>"))
for(q=j,p=q.length,o=0;o<q.length;q.length===p||(0,A.n)(q),++o){r=q[o]
n=r
if(n==null)n=l.a(n)
J.ae(s,n)}m.c.ca(s)}}else if(J.az(k,0)&&!m.f){s=l.d
s.toString
l=l.c
l.toString
m.c.bl(new A.aK(s,l))}},
$S(){return this.d.i("aE(0)")}}
A.hZ.prototype={
fd(a,b){var s=this.a
if((s.a&30)!==0)throw A.c(A.fb("Future already completed"))
s.c7(A.v7(a,b))}}
A.fo.prototype={
fc(a){var s=this.a
if((s.a&30)!==0)throw A.c(A.fb("Future already completed"))
s.dZ(a)}}
A.dV.prototype={
iX(a){if((this.c&15)!==6)return!0
return this.b.b.bG(this.d,a.a,t.y,t.C)},
iH(a){var s,r=this.e,q=null,p=t.z,o=t.C,n=a.a,m=this.b.b
if(t.ag.b(r))q=m.fv(r,n,a.b,p,o,t.l)
else q=m.bG(r,n,p,o)
try{p=q
return p}catch(s){if(t.eK.b(A.aV(s))){if((this.c&1)!==0)throw A.c(A.bn("The error handler of Future.then must return a value of the returned future's type","onError"))
throw A.c(A.bn("The error handler of Future.catchError must return a value of the future's type","onError"))}else throw s}}}
A.ad.prototype={
cH(a,b,c){var s,r,q=$.V
if(q===B.m){if(b!=null&&!t.ag.b(b)&&!t.bI.b(b))throw A.c(A.oC(b,"onError",u.c))}else{a=q.cG(a,c.i("0/"),this.$ti.c)
if(b!=null)b=A.vs(b,q)}s=new A.ad($.V,c.i("ad<0>"))
r=b==null?1:3
this.cT(new A.dV(s,r,a,b,this.$ti.i("@<1>").ar(c).i("dV<1,2>")))
return s},
f1(a,b,c){var s=new A.ad($.V,c.i("ad<0>"))
this.cT(new A.dV(s,19,a,b,this.$ti.i("@<1>").ar(c).i("dV<1,2>")))
return s},
ii(a){this.a=this.a&1|16
this.c=a},
c8(a){this.a=a.a&30|this.a&1
this.c=a.c},
cT(a){var s=this,r=s.a
if(r<=3){a.a=s.c
s.c=a}else{if((r&4)!==0){r=s.c
if((r.a&24)===0){r.cT(a)
return}s.c8(r)}s.b.bi(new A.nu(s,a))}},
eM(a){var s,r,q,p,o,n=this,m={}
m.a=a
if(a==null)return
s=n.a
if(s<=3){r=n.c
n.c=a
if(r!=null){q=a.a
for(p=a;q!=null;p=q,q=o)o=q.a
p.a=r}}else{if((s&4)!==0){s=n.c
if((s.a&24)===0){s.eM(a)
return}n.c8(s)}m.a=n.cg(a)
n.b.bi(new A.nz(m,n))}},
bU(){var s=this.c
this.c=null
return this.cg(s)},
cg(a){var s,r,q
for(s=a,r=null;s!=null;r=s,s=q){q=s.a
s.a=r}return r},
ca(a){var s=this,r=s.bU()
s.a=8
s.c=a
A.cT(s,r)},
h3(a){var s,r,q,p=this
if((a.a&16)!==0){s=p.b
r=a.b
s=!(s===r||s.gb3()===r.gb3())}else s=!1
if(s)return
q=p.bU()
p.c8(a)
A.cT(p,q)},
bl(a){var s=this.bU()
this.ii(a)
A.cT(this,s)},
dZ(a){if(this.$ti.i("b8<1>").b(a)){this.e0(a)
return}this.h0(a)},
h0(a){this.a^=2
this.b.bi(new A.nw(this,a))},
e0(a){A.nx(a,this,!1)
return},
c7(a){this.a^=2
this.b.bi(new A.nv(this,a))},
$ib8:1}
A.nu.prototype={
$0(){A.cT(this.a,this.b)},
$S:2}
A.nz.prototype={
$0(){A.cT(this.b,this.a.a)},
$S:2}
A.ny.prototype={
$0(){A.nx(this.a.a,this.b,!0)},
$S:2}
A.nw.prototype={
$0(){this.a.ca(this.b)},
$S:2}
A.nv.prototype={
$0(){this.a.bl(this.b)},
$S:2}
A.nC.prototype={
$0(){var s,r,q,p,o,n,m,l,k=this,j=null
try{q=k.a.a
j=q.b.b.bF(q.d,t.z)}catch(p){s=A.aV(p)
r=A.bN(p)
if(k.c&&k.b.a.c.a===s){q=k.a
q.c=k.b.a.c}else{q=s
o=r
if(o==null)o=A.iu(q)
n=k.a
n.c=new A.aK(q,o)
q=n}q.b=!0
return}if(j instanceof A.ad&&(j.a&24)!==0){if((j.a&16)!==0){q=k.a
q.c=j.c
q.b=!0}return}if(j instanceof A.ad){m=k.b.a
l=new A.ad(m.b,m.$ti)
j.cH(new A.nD(l,m),new A.nE(l),t.H)
q=k.a
q.c=l
q.b=!1}},
$S:2}
A.nD.prototype={
$1(a){this.a.h3(this.b)},
$S:33}
A.nE.prototype={
$2(a,b){this.a.bl(new A.aK(a,b))},
$S:65}
A.nB.prototype={
$0(){var s,r,q,p,o,n
try{q=this.a
p=q.a
o=p.$ti
q.c=p.b.b.bG(p.d,this.b,o.i("2/"),o.c)}catch(n){s=A.aV(n)
r=A.bN(n)
q=s
p=r
if(p==null)p=A.iu(q)
o=this.a
o.c=new A.aK(q,p)
o.b=!0}},
$S:2}
A.nA.prototype={
$0(){var s,r,q,p,o,n,m,l=this
try{s=l.a.a.c
p=l.b
if(p.a.iX(s)&&p.a.e!=null){p.c=p.a.iH(s)
p.b=!1}}catch(o){r=A.aV(o)
q=A.bN(o)
p=l.a.a.c
if(p.a===r){n=l.b
n.c=p
p=n}else{p=r
n=q
if(n==null)n=A.iu(p)
m=l.b
m.c=new A.aK(p,n)
p=m}p.b=!0}},
$S:2}
A.hY.prototype={}
A.i2.prototype={}
A.i1.prototype={}
A.ic.prototype={}
A.aU.prototype={}
A.ii.prototype={
dk(a,b,c){var s,r,q,p,o,n,m,l,k=this.gd5(),j=k.a
if(j===B.m){A.o5(b,c)
return}s=k.b
r=j.gaL()
m=j.gfo()
m.toString
q=m
p=$.V
try{$.V=q
s.$5(j,r,a,b,c)
$.V=p}catch(l){o=A.aV(l)
n=A.bN(l)
$.V=p
m=b===o?c:n
q.dk(j,o,m)}},
$iI:1}
A.i0.prototype={
gec(){var s=this.at
return s==null?this.at=new A.dX(this):s},
gaL(){return this.ax.gec()},
gb3(){return this.as.a},
dM(a){var s,r,q
try{this.bF(a,t.H)}catch(q){s=A.aV(q)
r=A.bN(q)
this.dk(this,s,r)}},
ds(a,b){return new A.np(this,this.cF(a,b),b)},
fb(a,b,c){return new A.nq(this,this.cG(a,b,c),c,b)},
dt(a){return new A.no(this,this.cF(a,t.H))},
h(a,b){var s,r=this.ay,q=r.h(0,b)
if(q!=null||r.F(b))return q
s=this.ax.h(0,b)
if(s!=null)r.k(0,b,s)
return s},
dA(a,b){this.dk(this,a,b)},
fk(a,b){var s=this.Q,r=s.a
return s.b.$5(r,r.gaL(),this,a,b)},
bF(a){var s=this.a,r=s.a
return s.b.$4(r,r.gaL(),this,a)},
bG(a,b){var s=this.b,r=s.a
return s.b.$5(r,r.gaL(),this,a,b)},
fv(a,b,c){var s=this.c,r=s.a
return s.b.$6(r,r.gaL(),this,a,b,c)},
cF(a){var s=this.d,r=s.a
return s.b.$4(r,r.gaL(),this,a)},
cG(a){var s=this.e,r=s.a
return s.b.$4(r,r.gaL(),this,a)},
dK(a){var s=this.f,r=s.a
return s.b.$4(r,r.gaL(),this,a)},
fh(a,b){var s=this.r,r=s.a
if(r===B.m)return null
return s.b.$5(r,r.gaL(),this,a,b)},
bi(a){var s=this.w,r=s.a
return s.b.$4(r,r.gaL(),this,a)},
fq(a){var s=this.z,r=s.a
return s.b.$4(r,r.gaL(),this,a)},
geU(){return this.a},
geW(){return this.b},
geV(){return this.c},
geR(){return this.d},
geS(){return this.e},
geQ(){return this.f},
gee(){return this.r},
gdm(){return this.w},
ge9(){return this.x},
ge8(){return this.y},
geN(){return this.z},
gen(){return this.Q},
gd5(){return this.as},
gfo(){return this.ax},
geA(){return this.ay}}
A.np.prototype={
$0(){return this.a.bF(this.b,this.c)},
$S(){return this.c.i("0()")}}
A.nq.prototype={
$1(a){var s=this
return s.a.bG(s.b,a,s.d,s.c)},
$S(){return this.d.i("@<0>").ar(this.c).i("1(2)")}}
A.no.prototype={
$0(){return this.a.dM(this.b)},
$S:2}
A.ib.prototype={
geU(){return B.dh},
geW(){return B.dj},
geV(){return B.di},
geR(){return B.dg},
geS(){return B.db},
geQ(){return B.dl},
gee(){return B.dd},
gdm(){return B.dk},
ge9(){return B.dc},
ge8(){return B.da},
geN(){return B.df},
gen(){return B.de},
gd5(){return B.d9},
gfo(){return null},
geA(){return $.rB()},
gec(){var s=$.nO
return s==null?$.nO=new A.dX(this):s},
gaL(){var s=$.nO
return s==null?$.nO=new A.dX(this):s},
gb3(){return this},
dM(a){var s,r,q
try{if(B.m===$.V){a.$0()
return}A.o7(null,null,this,a)}catch(q){s=A.aV(q)
r=A.bN(q)
A.o5(s,r)}},
ds(a,b){return new A.nQ(this,a,b)},
fb(a,b,c){return new A.nR(this,a,c,b)},
dt(a){return new A.nP(this,a)},
h(a,b){return null},
dA(a,b){A.o5(a,b)},
fk(a,b){return A.qU(null,null,this,a,b)},
bF(a){if($.V===B.m)return a.$0()
return A.o7(null,null,this,a)},
bG(a,b){if($.V===B.m)return a.$1(b)
return A.pp(null,null,this,a,b)},
fv(a,b,c){if($.V===B.m)return a.$2(b,c)
return A.po(null,null,this,a,b,c)},
cF(a){return a},
cG(a){return a},
dK(a){return a},
fh(a,b){return null},
bi(a){A.o8(null,null,this,a)},
fq(a){A.pw(a)}}
A.nQ.prototype={
$0(){return this.a.bF(this.b,this.c)},
$S(){return this.c.i("0()")}}
A.nR.prototype={
$1(a){var s=this
return s.a.bG(s.b,a,s.d,s.c)},
$S(){return this.d.i("@<0>").ar(this.c).i("1(2)")}}
A.nP.prototype={
$0(){return this.a.dM(this.b)},
$S:2}
A.dX.prototype={$iak:1}
A.o6.prototype={
$0(){A.t9(this.a,this.b)},
$S:2}
A.ij.prototype={$ip8:1}
A.fs.prototype={
gt(a){return this.a},
ga9(a){return this.a===0},
gaa(a){return this.a!==0},
gZ(){return new A.cU(this,A.E(this).i("cU<1>"))},
gaP(){var s=A.E(this)
return A.oY(new A.cU(this,s.i("cU<1>")),new A.nF(this),s.c,s.y[1])},
F(a){var s,r
if(typeof a=="string"&&a!=="__proto__"){s=this.b
return s==null?!1:s[a]!=null}else if(typeof a=="number"&&(a&1073741823)===a){r=this.c
return r==null?!1:r[a]!=null}else return this.h7(a)},
h7(a){var s=this.d
if(s==null)return!1
return this.b7(this.eo(s,a),a)>=0},
h(a,b){var s,r,q
if(typeof b=="string"&&b!=="__proto__"){s=this.b
r=s==null?null:A.p9(s,b)
return r}else if(typeof b=="number"&&(b&1073741823)===b){q=this.c
r=q==null?null:A.p9(q,b)
return r}else return this.hJ(b)},
hJ(a){var s,r,q=this.d
if(q==null)return null
s=this.eo(q,a)
r=this.b7(s,a)
return r<0?null:s[r+1]},
k(a,b,c){var s,r,q=this
if(typeof b=="string"&&b!=="__proto__"){s=q.b
q.e6(s==null?q.b=A.pa():s,b,c)}else if(typeof b=="number"&&(b&1073741823)===b){r=q.c
q.e6(r==null?q.c=A.pa():r,b,c)}else q.ih(b,c)},
ih(a,b){var s,r,q,p=this,o=p.d
if(o==null)o=p.d=A.pa()
s=p.bm(a)
r=o[s]
if(r==null){A.pb(o,s,[a,b]);++p.a
p.e=null}else{q=p.b7(r,a)
if(q>=0)r[q+1]=b
else{r.push(a,b);++p.a
p.e=null}}},
I(a,b){var s,r,q=this
if(q.F(a)){s=q.h(0,a)
return s==null?A.E(q).y[1].a(s):s}r=b.$0()
q.k(0,a,r)
return r},
S(a,b){var s=this
if(typeof b=="string"&&b!=="__proto__")return s.bT(s.b,b)
else if(typeof b=="number"&&(b&1073741823)===b)return s.bT(s.c,b)
else return s.dl(b)},
dl(a){var s,r,q,p,o=this,n=o.d
if(n==null)return null
s=o.bm(a)
r=n[s]
q=o.b7(r,a)
if(q<0)return null;--o.a
o.e=null
p=r.splice(q,2)[1]
if(0===r.length)delete n[s]
return p},
a0(a,b){var s,r,q,p,o,n=this,m=n.e7()
for(s=m.length,r=A.E(n).y[1],q=0;q<s;++q){p=m[q]
o=n.h(0,p)
b.$2(p,o==null?r.a(o):o)
if(m!==n.e)throw A.c(A.aA(n))}},
e7(){var s,r,q,p,o,n,m,l,k,j,i=this,h=i.e
if(h!=null)return h
h=A.a9(i.a,null,!1,t.z)
s=i.b
r=0
if(s!=null){q=Object.getOwnPropertyNames(s)
p=q.length
for(o=0;o<p;++o){h[r]=q[o];++r}}n=i.c
if(n!=null){q=Object.getOwnPropertyNames(n)
p=q.length
for(o=0;o<p;++o){h[r]=+q[o];++r}}m=i.d
if(m!=null){q=Object.getOwnPropertyNames(m)
p=q.length
for(o=0;o<p;++o){l=m[q[o]]
k=l.length
for(j=0;j<k;j+=2){h[r]=l[j];++r}}}return i.e=h},
e6(a,b,c){if(a[b]==null){++this.a
this.e=null}A.pb(a,b,c)},
bT(a,b){var s
if(a!=null&&a[b]!=null){s=A.p9(a,b)
delete a[b];--this.a
this.e=null
return s}else return null},
bm(a){return J.by(a)&1073741823},
eo(a,b){return a[this.bm(b)]},
b7(a,b){var s,r
if(a==null)return-1
s=a.length
for(r=0;r<s;r+=2)if(J.az(a[r],b))return r
return-1}}
A.nF.prototype={
$1(a){var s=this.a,r=s.h(0,a)
return r==null?A.E(s).y[1].a(r):r},
$S(){return A.E(this.a).i("2(1)")}}
A.cU.prototype={
gt(a){return this.a.a},
ga9(a){return this.a.a===0},
gaa(a){return this.a.a!==0},
gJ(a){var s=this.a
return new A.ft(s,s.e7(),this.$ti.i("ft<1>"))},
E(a,b){return this.a.F(b)}}
A.ft.prototype={
gD(){var s=this.d
return s==null?this.$ti.c.a(s):s},
p(){var s=this,r=s.b,q=s.c,p=s.a
if(r!==p.e)throw A.c(A.aA(p))
else if(q>=r.length){s.d=null
return!1}else{s.d=r[q]
s.c=q+1
return!0}},
$ia2:1}
A.cX.prototype={
gJ(a){var s=this,r=new A.c7(s,s.r,A.E(s).i("c7<1>"))
r.c=s.e
return r},
gt(a){return this.a},
ga9(a){return this.a===0},
gaa(a){return this.a!==0},
E(a,b){var s,r
if(typeof b=="string"&&b!=="__proto__"){s=this.b
if(s==null)return!1
return s[b]!=null}else if(typeof b=="number"&&(b&1073741823)===b){r=this.c
if(r==null)return!1
return r[b]!=null}else return this.h6(b)},
h6(a){var s=this.d
if(s==null)return!1
return this.b7(s[this.bm(a)],a)>=0},
gH(a){var s=this.e
if(s==null)throw A.c(A.fb("No elements"))
return s.a},
T(a,b){var s,r,q=this
if(typeof b=="string"&&b!=="__proto__"){s=q.b
return q.e5(s==null?q.b=A.pc():s,b)}else if(typeof b=="number"&&(b&1073741823)===b){r=q.c
return q.e5(r==null?q.c=A.pc():r,b)}else return q.fW(b)},
fW(a){var s,r,q=this,p=q.d
if(p==null)p=q.d=A.pc()
s=q.bm(a)
r=p[s]
if(r==null)p[s]=[q.cX(a)]
else{if(q.b7(r,a)>=0)return!1
r.push(q.cX(a))}return!0},
S(a,b){var s=this
if(typeof b=="string"&&b!=="__proto__")return s.bT(s.b,b)
else if(typeof b=="number"&&(b&1073741823)===b)return s.bT(s.c,b)
else return s.dl(b)},
dl(a){var s,r,q,p,o=this,n=o.d
if(n==null)return!1
s=o.bm(a)
r=n[s]
q=o.b7(r,a)
if(q<0)return!1
p=r.splice(q,1)[0]
if(0===r.length)delete n[s]
o.f3(p)
return!0},
v(a){var s=this
if(s.a>0){s.b=s.c=s.d=s.e=s.f=null
s.a=0
s.cW()}},
e5(a,b){if(a[b]!=null)return!1
a[b]=this.cX(b)
return!0},
bT(a,b){var s
if(a==null)return!1
s=a[b]
if(s==null)return!1
this.f3(s)
delete a[b]
return!0},
cW(){this.r=this.r+1&1073741823},
cX(a){var s,r=this,q=new A.nM(a)
if(r.e==null)r.e=r.f=q
else{s=r.f
s.toString
q.c=s
r.f=s.b=q}++r.a
r.cW()
return q},
f3(a){var s=this,r=a.c,q=a.b
if(r==null)s.e=q
else r.b=q
if(q==null)s.f=r
else q.c=r;--s.a
s.cW()},
bm(a){return J.by(a)&1073741823},
b7(a,b){var s,r
if(a==null)return-1
s=a.length
for(r=0;r<s;++r)if(J.az(a[r].a,b))return r
return-1}}
A.nM.prototype={}
A.c7.prototype={
gD(){var s=this.d
return s==null?this.$ti.c.a(s):s},
p(){var s=this,r=s.c,q=s.a
if(s.b!==q.r)throw A.c(A.aA(q))
else if(r==null){s.d=null
return!1}else{s.d=r.a
s.c=r.b
return!0}},
$ia2:1}
A.jr.prototype={
$2(a,b){this.a.k(0,this.b.a(a),this.c.a(b))},
$S:4}
A.lS.prototype={
$2(a,b){this.a.k(0,this.b.a(a),this.c.a(b))},
$S:4}
A.a3.prototype={
gJ(a){return new A.cL(a,this.gt(a),A.bO(a).i("cL<a3.E>"))},
an(a,b){return this.h(a,b)},
ga9(a){return this.gt(a)===0},
gaa(a){return this.gt(a)!==0},
gH(a){if(this.gt(a)===0)throw A.c(A.bX())
return this.h(a,0)},
gW(a){if(this.gt(a)===0)throw A.c(A.bX())
return this.h(a,this.gt(a)-1)},
E(a,b){var s,r=this.gt(a)
for(s=0;s<r;++s){this.h(a,s)
if(r!==this.gt(a))throw A.c(A.aA(a))}return!1},
cr(a,b){var s,r=this.gt(a)
for(s=0;s<r;++s){if(!b.$1(this.h(a,s)))return!1
if(r!==this.gt(a))throw A.c(A.aA(a))}return!0},
b2(a,b){var s,r=this.gt(a)
for(s=0;s<r;++s){if(b.$1(this.h(a,s)))return!0
if(r!==this.gt(a))throw A.c(A.aA(a))}return!1},
R(a,b){var s
if(this.gt(a)===0)return""
s=A.p5("",a,b)
return s.charCodeAt(0)==0?s:s},
bc(a,b,c){return new A.h(a,b,A.bO(a).i("@<a3.E>").ar(c).i("h<1,2>"))},
fj(a,b,c){return new A.bV(a,b,A.bO(a).i("@<a3.E>").ar(c).i("bV<1,2>"))},
aS(a,b){var s,r,q,p,o=this
if(o.gt(a)===0){s=J.oR(0,A.bO(a).i("a3.E"))
return s}r=o.h(a,0)
q=A.a9(o.gt(a),r,!0,A.bO(a).i("a3.E"))
for(p=1;p<o.gt(a);++p)q[p]=o.h(a,p)
return q},
aO(a){return this.aS(a,!0)},
T(a,b){var s=this.gt(a)
this.st(a,s+1)
this.k(a,s,b)},
S(a,b){var s
for(s=0;s<this.gt(a);++s)this.h(a,s)
return!1},
aq(a,b){A.hJ(a,0,this.gt(a)-1,b)},
bC(a,b,c,d){var s
A.c2(b,c,this.gt(a))
for(s=b;s<c;++s)this.k(a,s,d)},
aF(a,b,c,d,e){var s,r,q
A.c2(b,c,this.gt(a))
s=c-b
if(s===0)return
A.eU(e,"skipCount")
r=J.X(d)
if(e+s>r.gt(d))throw A.c(A.q_())
if(e<b)for(q=s-1;q>=0;--q)this.k(a,b+q,r.h(d,e+q))
else for(q=0;q<s;++q)this.k(a,b+q,r.h(d,e+q))},
a8(a,b,c,d){return this.aF(a,b,c,d,0)},
aj(a,b,c){this.a8(a,b,b+c.length,c)},
l(a){return A.oQ(a,"[","]")},
$iJ:1,
$it:1}
A.aa.prototype={
a0(a,b){var s,r,q,p
for(s=this.gZ(),s=s.gJ(s),r=A.E(this).i("aa.V");s.p();){q=s.gD()
p=this.h(0,q)
b.$2(q,p==null?r.a(p):p)}},
I(a,b){var s,r=this
if(r.F(a)){s=r.h(0,a)
return s==null?A.E(r).i("aa.V").a(s):s}s=b.$0()
r.k(0,a,s)
return s},
gbZ(){return this.gZ().bc(0,new A.lT(this),A.E(this).i("aj<aa.K,aa.V>"))},
dG(a,b,c,d){var s,r,q,p,o,n=A.o(c,d)
for(s=this.gZ(),s=s.gJ(s),r=A.E(this).i("aa.V");s.p();){q=s.gD()
p=this.h(0,q)
o=b.$2(q,p==null?r.a(p):p)
n.k(0,o.a,o.b)}return n},
j7(a,b){var s,r,q,p,o=this,n=A.E(o),m=A.a([],n.i("C<aa.K>"))
for(s=o.gZ(),s=s.gJ(s),n=n.i("aa.V");s.p();){r=s.gD()
q=o.h(0,r)
if(b.$2(r,q==null?n.a(q):q))m.push(r)}for(n=m.length,p=0;p<m.length;m.length===n||(0,A.n)(m),++p)o.S(0,m[p])},
F(a){return this.gZ().E(0,a)},
gt(a){var s=this.gZ()
return s.gt(s)},
ga9(a){var s=this.gZ()
return s.ga9(s)},
gaa(a){var s=this.gZ()
return s.gaa(s)},
gaP(){return new A.fu(this,A.E(this).i("fu<aa.K,aa.V>"))},
l(a){return A.oX(this)},
$iw:1}
A.lT.prototype={
$1(a){var s=this.a,r=s.h(0,a)
if(r==null)r=A.E(s).i("aa.V").a(r)
return new A.aj(a,r,A.E(s).i("aj<aa.K,aa.V>"))},
$S(){return A.E(this.a).i("aj<aa.K,aa.V>(aa.K)")}}
A.lU.prototype={
$2(a,b){var s,r=this.a
if(!r.a)this.b.a+=", "
r.a=!1
r=this.b
s=A.D(a)
r.a=(r.a+=s)+": "
s=A.D(b)
r.a+=s},
$S:51}
A.fu.prototype={
gt(a){var s=this.a
return s.gt(s)},
ga9(a){var s=this.a
return s.ga9(s)},
gaa(a){var s=this.a
return s.gaa(s)},
gH(a){var s=this.a,r=s.gZ()
r=s.h(0,r.gH(r))
return r==null?this.$ti.y[1].a(r):r},
gJ(a){var s=this.a,r=s.gZ()
return new A.fv(r.gJ(r),s,this.$ti.i("fv<1,2>"))}}
A.fv.prototype={
p(){var s=this,r=s.a
if(r.p()){s.c=s.b.h(0,r.gD())
return!0}s.c=null
return!1},
gD(){var s=this.c
return s==null?this.$ti.y[1].a(s):s},
$ia2:1}
A.cl.prototype={
ga9(a){return this.gt(this)===0},
gaa(a){return this.gt(this)!==0},
X(a,b){var s
for(s=J.as(b);s.p();)this.T(0,s.gD())},
aS(a,b){var s=A.r(this,A.E(this).c)
return s},
aO(a){return this.aS(0,!0)},
l(a){return A.oQ(this,"{","}")},
gH(a){var s=this.gJ(this)
if(!s.p())throw A.c(A.bX())
return s.gD()},
$iJ:1,
$ic3:1}
A.fB.prototype={}
A.i5.prototype={
h(a,b){var s,r=this.b
if(r==null)return this.c.h(0,b)
else if(typeof b!="string")return null
else{s=r[b]
return typeof s=="undefined"?this.i6(b):s}},
gt(a){return this.b==null?this.c.a:this.bw().length},
ga9(a){return this.gt(0)===0},
gaa(a){return this.gt(0)>0},
gZ(){if(this.b==null){var s=this.c
return new A.aB(s,A.E(s).i("aB<1>"))}return new A.i6(this)},
gaP(){var s,r=this
if(r.b==null){s=r.c
return new A.b1(s,A.E(s).i("b1<2>"))}return A.oY(r.bw(),new A.nI(r),t.N,t.z)},
k(a,b,c){var s,r,q=this
if(q.b==null)q.c.k(0,b,c)
else if(q.F(b)){s=q.b
s[b]=c
r=q.a
if(r==null?s!=null:r!==s)r[b]=null}else q.f4().k(0,b,c)},
F(a){if(this.b==null)return this.c.F(a)
if(typeof a!="string")return!1
return Object.prototype.hasOwnProperty.call(this.a,a)},
I(a,b){var s
if(this.F(a))return this.h(0,a)
s=b.$0()
this.k(0,a,s)
return s},
S(a,b){if(this.b!=null&&!this.F(b))return null
return this.f4().S(0,b)},
a0(a,b){var s,r,q,p,o=this
if(o.b==null)return o.c.a0(0,b)
s=o.bw()
for(r=0;r<s.length;++r){q=s[r]
p=o.b[q]
if(typeof p=="undefined"){p=A.o2(o.a[q])
o.b[q]=p}b.$2(q,p)
if(s!==o.c)throw A.c(A.aA(o))}},
bw(){var s=this.c
if(s==null)s=this.c=A.a(Object.keys(this.a),t.s)
return s},
f4(){var s,r,q,p,o,n=this
if(n.b==null)return n.c
s=A.o(t.N,t.z)
r=n.bw()
for(q=0;p=r.length,q<p;++q){o=r[q]
s.k(0,o,n.h(0,o))}if(p===0)r.push("")
else B.b.v(r)
n.a=n.b=null
return n.c=s},
i6(a){var s
if(!Object.prototype.hasOwnProperty.call(this.a,a))return null
s=A.o2(this.a[a])
return this.b[a]=s}}
A.nI.prototype={
$1(a){return this.a.h(0,a)},
$S:54}
A.i6.prototype={
gt(a){return this.a.gt(0)},
an(a,b){var s=this.a
return s.b==null?s.gZ().an(0,b):s.bw()[b]},
gJ(a){var s=this.a
if(s.b==null){s=s.gZ()
s=s.gJ(s)}else{s=s.bw()
s=new J.be(s,s.length,A.z(s).i("be<1>"))}return s},
E(a,b){return this.a.F(b)}}
A.nY.prototype={
$0(){var s,r
try{s=new TextDecoder("utf-8",{fatal:true})
return s}catch(r){}return null},
$S:50}
A.nX.prototype={
$0(){var s,r
try{s=new TextDecoder("utf-8",{fatal:false})
return s}catch(r){}return null},
$S:50}
A.fW.prototype={}
A.fZ.prototype={}
A.iZ.prototype={}
A.eC.prototype={
l(a){var s=A.h4(this.a)
return(this.b!=null?"Converting object to an encodable object failed:":"Converting object did not return an encodable object:")+" "+s}}
A.hm.prototype={
l(a){return"Cyclic error in JSON stringify"}}
A.lO.prototype={
ag(a){var s=A.vo(a,this.gix().a)
return s},
dw(a,b){var s=A.ug(a,this.giy().b,null)
return s},
bB(a){return this.dw(a,null)},
giy(){return B.cG},
gix(){return B.cF}}
A.lQ.prototype={}
A.lP.prototype={}
A.nK.prototype={
fC(a){var s,r,q,p,o,n,m=a.length
for(s=this.c,r=0,q=0;q<m;++q){p=a.charCodeAt(q)
if(p>92){if(p>=55296){o=p&64512
if(o===55296){n=q+1
n=!(n<m&&(a.charCodeAt(n)&64512)===56320)}else n=!1
if(!n)if(o===56320){o=q-1
o=!(o>=0&&(a.charCodeAt(o)&64512)===55296)}else o=!1
else o=!0
if(o){if(q>r)s.a+=B.a.O(a,r,q)
r=q+1
o=A.au(92)
s.a+=o
o=A.au(117)
s.a+=o
o=A.au(100)
s.a+=o
o=p>>>8&15
o=A.au(o<10?48+o:87+o)
s.a+=o
o=p>>>4&15
o=A.au(o<10?48+o:87+o)
s.a+=o
o=p&15
o=A.au(o<10?48+o:87+o)
s.a+=o}}continue}if(p<32){if(q>r)s.a+=B.a.O(a,r,q)
r=q+1
o=A.au(92)
s.a+=o
switch(p){case 8:o=A.au(98)
s.a+=o
break
case 9:o=A.au(116)
s.a+=o
break
case 10:o=A.au(110)
s.a+=o
break
case 12:o=A.au(102)
s.a+=o
break
case 13:o=A.au(114)
s.a+=o
break
default:o=A.au(117)
s.a+=o
o=A.au(48)
s.a=(s.a+=o)+o
o=p>>>4&15
o=A.au(o<10?48+o:87+o)
s.a+=o
o=p&15
o=A.au(o<10?48+o:87+o)
s.a+=o
break}}else if(p===34||p===92){if(q>r)s.a+=B.a.O(a,r,q)
r=q+1
o=A.au(92)
s.a+=o
o=A.au(p)
s.a+=o}}if(r===0)s.a+=a
else if(r<m)s.a+=B.a.O(a,r,m)},
cV(a){var s,r,q,p
for(s=this.a,r=s.length,q=0;q<r;++q){p=s[q]
if(a==null?p==null:a===p)throw A.c(new A.hm(a,null))}s.push(a)},
cJ(a){var s,r,q,p,o=this
if(o.fB(a))return
o.cV(a)
try{s=o.b.$1(a)
if(!o.fB(s)){q=A.q4(a,null,o.geL())
throw A.c(q)}o.a.pop()}catch(p){r=A.aV(p)
q=A.q4(a,r,o.geL())
throw A.c(q)}},
fB(a){var s,r,q=this
if(typeof a=="number"){if(!isFinite(a))return!1
q.c.a+=B.h.l(a)
return!0}else if(a===!0){q.c.a+="true"
return!0}else if(a===!1){q.c.a+="false"
return!0}else if(a==null){q.c.a+="null"
return!0}else if(typeof a=="string"){s=q.c
s.a+='"'
q.fC(a)
s.a+='"'
return!0}else if(t.j.b(a)){q.cV(a)
q.jd(a)
q.a.pop()
return!0}else if(t.f.b(a)){q.cV(a)
r=q.je(a)
q.a.pop()
return r}else return!1},
jd(a){var s,r,q=this.c
q.a+="["
s=J.X(a)
if(s.gaa(a)){this.cJ(s.h(a,0))
for(r=1;r<s.gt(a);++r){q.a+=","
this.cJ(s.h(a,r))}}q.a+="]"},
je(a){var s,r,q,p,o,n=this,m={}
if(a.ga9(a)){n.c.a+="{}"
return!0}s=a.gt(a)*2
r=A.a9(s,null,!1,t.X)
q=m.a=0
m.b=!0
a.a0(0,new A.nL(m,r))
if(!m.b)return!1
p=n.c
p.a+="{"
for(o='"';q<s;q+=2,o=',"'){p.a+=o
n.fC(A.il(r[q]))
p.a+='":'
n.cJ(r[q+1])}p.a+="}"
return!0}}
A.nL.prototype={
$2(a,b){var s,r,q,p
if(typeof a!="string")this.a.b=!1
s=this.b
r=this.a
q=r.a
p=r.a=q+1
s[q]=a
r.a=p+1
s[p]=b},
$S:51}
A.nJ.prototype={
geL(){var s=this.c.a
return s.charCodeAt(0)==0?s:s}}
A.nc.prototype={
fg(a,b){return(b===!0?B.d8:B.d7).aB(a)},
ag(a){return this.fg(a,null)}}
A.nd.prototype={
aB(a){var s,r,q=A.c2(0,null,a.length)
if(q===0)return new Uint8Array(0)
s=new Uint8Array(q*3)
r=new A.nZ(s)
if(r.hG(a,0,q)!==q)r.dr()
return B.j.bk(s,0,r.b)}}
A.nZ.prototype={
dr(){var s=this,r=s.c,q=s.b,p=s.b=q+1
r.$flags&2&&A.i(r)
r[q]=239
q=s.b=p+1
r[p]=191
s.b=q+1
r[q]=189},
ip(a,b){var s,r,q,p,o=this
if((b&64512)===56320){s=65536+((a&1023)<<10)|b&1023
r=o.c
q=o.b
p=o.b=q+1
r.$flags&2&&A.i(r)
r[q]=s>>>18|240
q=o.b=p+1
r[p]=s>>>12&63|128
p=o.b=q+1
r[q]=s>>>6&63|128
o.b=p+1
r[p]=s&63|128
return!0}else{o.dr()
return!1}},
hG(a,b,c){var s,r,q,p,o,n,m,l,k=this
if(b!==c&&(a.charCodeAt(c-1)&64512)===55296)--c
for(s=k.c,r=s.$flags|0,q=s.length,p=b;p<c;++p){o=a.charCodeAt(p)
if(o<=127){n=k.b
if(n>=q)break
k.b=n+1
r&2&&A.i(s)
s[n]=o}else{n=o&64512
if(n===55296){if(k.b+4>q)break
m=p+1
if(k.ip(o,a.charCodeAt(m)))p=m}else if(n===56320){if(k.b+3>q)break
k.dr()}else if(o<=2047){n=k.b
l=n+1
if(l>=q)break
k.b=l
r&2&&A.i(s)
s[n]=o>>>6|192
k.b=l+1
s[l]=o&63|128}else{n=k.b
if(n+2>=q)break
l=k.b=n+1
r&2&&A.i(s)
s[n]=o>>>12|224
n=k.b=l+1
s[l]=o>>>6&63|128
k.b=n+1
s[n]=o&63|128}}}return p}}
A.hR.prototype={
aB(a){return new A.cZ(this.a).bJ(a,0,null,!0)}}
A.cZ.prototype={
bJ(a,b,c,d){var s,r,q,p,o,n,m=this,l=A.c2(b,c,a.length)
if(b===l)return""
if(a instanceof Uint8Array){s=a
r=s
q=0}else{r=A.uG(a,b,l)
l-=b
q=b
b=0}if(l-b>=15){p=m.a
o=A.uF(p,r,b,l)
if(o!=null){if(!p)return o
if(o.indexOf("\ufffd")<0)return o}}o=m.cZ(r,b,l,!0)
p=m.b
if((p&1)!==0){n=A.uH(p)
m.b=0
throw A.c(A.cf(n,a,q+m.c))}return o},
cZ(a,b,c,d){var s,r,q=this
if(c-b>1000){s=B.c.a3(b+c,2)
r=q.cZ(a,b,s,!1)
if((q.b&1)!==0)return r
return r+q.cZ(a,s,c,d)}return q.iw(a,b,c,d)},
iw(a,b,c,d){var s,r,q,p,o,n,m,l=this,k=65533,j=l.b,i=l.c,h=new A.cn(""),g=b+1,f=a[b]
A:for(s=l.a;;){for(;;g=p){r="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAFFFFFFFFFFFFFFFFGGGGGGGGGGGGGGGGHHHHHHHHHHHHHHHHHHHHHHHHHHHIHHHJEEBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBKCCCCCCCCCCCCDCLONNNMEEEEEEEEEEE".charCodeAt(f)&31
i=j<=32?f&61694>>>r:(f&63|i<<6)>>>0
j=" \x000:XECCCCCN:lDb \x000:XECCCCCNvlDb \x000:XECCCCCN:lDb AAAAA\x00\x00\x00\x00\x00AAAAA00000AAAAA:::::AAAAAGG000AAAAA00KKKAAAAAG::::AAAAA:IIIIAAAAA000\x800AAAAA\x00\x00\x00\x00 AAAAA".charCodeAt(j+r)
if(j===0){q=A.au(i)
h.a+=q
if(g===c)break A
break}else if((j&1)!==0){if(s)switch(j){case 69:case 67:q=A.au(k)
h.a+=q
break
case 65:q=A.au(k)
h.a+=q;--g
break
default:q=A.au(k)
h.a=(h.a+=q)+q
break}else{l.b=j
l.c=g-1
return""}j=0}if(g===c)break A
p=g+1
f=a[g]}p=g+1
f=a[g]
if(f<128){for(;;){if(!(p<c)){o=c
break}n=p+1
f=a[p]
if(f>=128){o=n-1
p=n
break}p=n}if(o-g<20)for(m=g;m<o;++m){q=A.au(a[m])
h.a+=q}else{q=A.tS(a,g,o)
h.a+=q}if(o===c)break A
g=p}else g=p}if(d&&j>32)if(s){s=A.au(k)
h.a+=s}else{l.b=77
l.c=c
return""}l.b=j
l.c=i
s=h.a
return s.charCodeAt(0)==0?s:s}}
A.aw.prototype={
dY(a){var s=1000,r=B.c.a7(a,s),q=B.c.a3(a-r,s),p=this.b+r,o=B.c.a7(p,s),n=this.c
return new A.aw(A.oF(this.a+B.c.a3(p-o,s)+q,o,n),o,n)},
aw(a,b){if(b==null)return!1
return b instanceof A.aw&&this.a===b.a&&this.b===b.b&&this.c===b.c},
gY(a){return A.q9(this.a,this.b,B.V,B.V)},
A(a,b){var s=B.c.A(this.a,b.a)
if(s!==0)return s
return B.c.A(this.b,b.b)},
l(a){var s=this,r=A.pQ(A.b2(s)),q=A.bS(A.bB(s)),p=A.bS(A.bI(s)),o=A.bS(A.dJ(s)),n=A.bS(A.eQ(s)),m=A.bS(A.eR(s)),l=A.iR(A.qf(s)),k=s.b,j=k===0?"":A.iR(k)
k=r+"-"+q
if(s.c)return k+"-"+p+" "+o+":"+n+":"+m+"."+l+j+"Z"
else return k+"-"+p+" "+o+":"+n+":"+m+"."+l+j},
bt(){var s=this,r=A.b2(s)>=-9999&&A.b2(s)<=9999?A.pQ(A.b2(s)):A.t5(A.b2(s)),q=A.bS(A.bB(s)),p=A.bS(A.bI(s)),o=A.bS(A.dJ(s)),n=A.bS(A.eQ(s)),m=A.bS(A.eR(s)),l=A.iR(A.qf(s)),k=s.b,j=k===0?"":A.iR(k)
k=r+"-"+q
if(s.c)return k+"-"+p+"T"+o+":"+n+":"+m+"."+l+j+"Z"
else return k+"-"+p+"T"+o+":"+n+":"+m+"."+l+j}}
A.iS.prototype={
$1(a){if(a==null)return 0
return A.d4(a)},
$S:49}
A.iT.prototype={
$1(a){var s,r,q
if(a==null)return 0
for(s=a.length,r=0,q=0;q<6;++q){r*=10
if(q<s)r+=a.charCodeAt(q)^48}return r},
$S:49}
A.bU.prototype={
aw(a,b){if(b==null)return!1
return b instanceof A.bU&&this.a===b.a},
gY(a){return B.c.gY(this.a)},
A(a,b){return B.c.A(this.a,b.a)},
l(a){var s,r,q,p,o,n=this.a,m=B.c.a3(n,36e8),l=n%36e8
if(n<0){m=0-m
n=0-l
s="-"}else{n=l
s=""}r=B.c.a3(n,6e7)
n%=6e7
q=r<10?"0":""
p=B.c.a3(n,1e6)
o=p<10?"0":""
return s+m+":"+q+r+":"+o+p+"."+B.a.a1(B.c.l(n%1e6),6,"0")}}
A.nr.prototype={
l(a){return this.cb()}}
A.ah.prototype={
gbH(){return A.tE(this)}}
A.fS.prototype={
l(a){var s=this.a
if(s!=null)return"Assertion failed: "+A.h4(s)
return"Assertion failed"}}
A.c5.prototype={}
A.bz.prototype={
gd0(){return"Invalid argument"+(!this.a?"(s)":"")},
gd_(){return""},
l(a){var s=this,r=s.c,q=r==null?"":" ("+r+")",p=s.d,o=p==null?"":": "+A.D(p),n=s.gd0()+q+o
if(!s.a)return n
return n+s.gd_()+": "+A.h4(s.gdD())},
gdD(){return this.b}}
A.dL.prototype={
gdD(){return this.b},
gd0(){return"RangeError"},
gd_(){var s,r=this.e,q=this.f
if(r==null)s=q!=null?": Not less than or equal to "+A.D(q):""
else if(q==null)s=": Not greater than or equal to "+A.D(r)
else if(q>r)s=": Not in inclusive range "+A.D(r)+".."+A.D(q)
else s=q<r?": Valid value range is empty":": Only valid value is "+A.D(r)
return s}}
A.hd.prototype={
gdD(){return this.b},
gd0(){return"RangeError"},
gd_(){if(this.b<0)return": index must not be negative"
var s=this.f
if(s===0)return": no indices are valid"
return": index should be less than "+s},
gt(a){return this.f}}
A.fi.prototype={
l(a){return"Unsupported operation: "+this.a}}
A.hN.prototype={
l(a){return"UnimplementedError: "+this.a}}
A.cm.prototype={
l(a){return"Bad state: "+this.a}}
A.fY.prototype={
l(a){var s=this.a
if(s==null)return"Concurrent modification during iteration."
return"Concurrent modification during iteration: "+A.h4(s)+"."}}
A.ht.prototype={
l(a){return"Out of Memory"},
gbH(){return null},
$iah:1}
A.fa.prototype={
l(a){return"Stack Overflow"},
gbH(){return null},
$iah:1}
A.ns.prototype={
l(a){return"Exception: "+this.a}}
A.h8.prototype={
l(a){var s,r,q,p,o,n,m,l,k,j,i,h=this.a,g=""!==h?"FormatException: "+h:"FormatException",f=this.c,e=this.b
if(typeof e=="string"){if(f!=null)s=f<0||f>e.length
else s=!1
if(s)f=null
if(f==null){if(e.length>78)e=B.a.O(e,0,75)+"..."
return g+"\n"+e}for(r=1,q=0,p=!1,o=0;o<f;++o){n=e.charCodeAt(o)
if(n===10){if(q!==o||!p)++r
q=o+1
p=!1}else if(n===13){++r
q=o+1
p=!0}}g=r>1?g+(" (at line "+r+", character "+(f-q+1)+")\n"):g+(" (at character "+(f+1)+")\n")
m=e.length
for(o=f;o<m;++o){n=e.charCodeAt(o)
if(n===10||n===13){m=o
break}}l=""
if(m-q>78){k="..."
if(f-q<75){j=q+75
i=q}else{if(m-f<75){i=m-75
j=m
k=""}else{i=f-36
j=f+36}l="..."}}else{j=m
i=q
k=""}return g+l+B.a.O(e,i,j)+k+"\n"+B.a.P(" ",f-i+l.length)+"^\n"}else return f!=null?g+(" (at offset "+A.D(f)+")"):g}}
A.F.prototype={
bc(a,b,c){return A.oY(this,b,A.E(this).i("F.E"),c)},
E(a,b){var s
for(s=this.gJ(this);s.p();)if(J.az(s.gD(),b))return!0
return!1},
j5(a,b){var s,r=this.gJ(this)
if(!r.p())throw A.c(A.bX())
s=r.gD()
while(r.p())s=b.$2(s,r.gD())
return s},
aS(a,b){var s=A.r(this,A.E(this).i("F.E"))
return s},
aO(a){return this.aS(0,!0)},
gt(a){var s,r=this.gJ(this)
for(s=0;r.p();)++s
return s},
ga9(a){return!this.gJ(this).p()},
gaa(a){return!this.ga9(this)},
gH(a){var s=this.gJ(this)
if(!s.p())throw A.c(A.bX())
return s.gD()},
an(a,b){var s,r
A.eU(b,"index")
s=this.gJ(this)
for(r=b;s.p();){if(r===0)return s.gD();--r}throw A.c(A.oP(b,b-r,this,"index"))},
l(a){return A.tp(this,"(",")")}}
A.aj.prototype={
l(a){return"MapEntry("+A.D(this.a)+": "+A.D(this.b)+")"}}
A.aE.prototype={
gY(a){return A.A.prototype.gY.call(this,0)},
l(a){return"null"}}
A.A.prototype={$iA:1,
aw(a,b){return this===b},
gY(a){return A.hC(this)},
l(a){return"Instance of '"+A.eS(this)+"'"},
gak(a){return A.ip(this)},
toString(){return this.l(this)}}
A.ig.prototype={
l(a){return this.a},
$iaX:1}
A.fc.prototype={
gbY(){var s,r=this.b
if(r==null)r=$.cN.$0()
s=r-this.a
if($.ou()===1e6)return s
return s*1000},
cS(){var s=this,r=s.b
if(r!=null){s.a=s.a+($.cN.$0()-r)
s.b=null}}}
A.cn.prototype={
gt(a){return this.a.length},
l(a){var s=this.a
return s.charCodeAt(0)==0?s:s},
gaa(a){return this.a.length!==0}}
A.m_.prototype={
l(a){var s,r=this.a
if(r.length!==0){r="OS Error: "+r
s=this.b
if(s!==-1)r=r+", errno = "+B.c.l(s)}else{r=this.b
r=r!==-1?"OS Error: errno = "+B.c.l(r):"OS Error"}return r.charCodeAt(0)==0?r:r}}
A.fq.prototype={
gcC(){return this.a},
aX(){A.u5(A.bL(),this.b)},
bX(a){var s=this
if(s.aX())return
if(s.a!==A.dl(A.oI(s.gcC())).a)A.dl(A.oI(s.gcC())).bX(!0)
A.u2(A.bL(),s.b)},
bx(a){A.u4(A.bL(),this.b,a)},
l(a){return"Directory: '"+this.a+"'"}}
A.cD.prototype={}
A.dp.prototype={
cj(a){var s,r=this,q=r.a
if(q.length!==0){q=a+(": "+q)+(", path = '"+r.b+"'")
s=r.c
if(s!=null)q+=" ("+s.l(0)+")"}else{q=r.c
if(q!=null)q=a+(": "+q.l(0))+(", path = '"+r.b+"'")
else q=a+(": "+r.b)}return q.charCodeAt(0)==0?q:q},
l(a){return this.cj("FileSystemException")}}
A.hy.prototype={
l(a){return this.cj("PathAccessException")}}
A.hz.prototype={
l(a){return this.cj("PathExistsException")}}
A.hA.prototype={
l(a){return this.cj("PathNotFoundException")}}
A.fr.prototype={
gcC(){return this.a},
aX(){A.ub(A.bL(),this.b)},
bX(a){if(a)A.dl(A.oI(this.gcC())).bX(!0)
A.u8(A.bL(),this.b,!1)},
bx(a){var s,r
if(a){s=this.b
r=A.oH(s)
return new A.fq(B.a5.fg(B.j.gW(s)===0?J.bm(B.j.gai(s),s.byteOffset,s.length-1):s,!0),r).bx(!0)}A.u9(A.bL(),this.b)},
iS(a){return A.ua(12,[null,this.b]).jm(new A.nt(this),t.S)},
iY(a){if(a!==B.cx&&a!==B.cy&&a!==B.b8&&a!==B.cz&&a!==B.cA)throw A.c(A.bn("Invalid file mode for this operation",null))
A.ud(A.bL(),this.b,a.a)},
l(a){return"File: '"+this.a+"'"}}
A.nt.prototype={
$1(a){A.uW(a,"Cannot retrieve length of file",this.a.a)
return a},
$S:85}
A.dn.prototype={}
A.jc.prototype={
$2(a,b){this.a.cH(new A.ja(a),new A.jb(b),t.X)},
$S:136}
A.ja.prototype={
$1(a){var s=this.a
s.call(s,a)
return a},
$S:128}
A.jb.prototype={
$2(a,b){var s,r,q=t.g.a(v.G.Error),p=A.w_(q,["Dart exception thrown from converted Future. Use the properties 'error' to fetch the boxed error and 'stack' to recover the stack trace."])
if(t.aX.b(a))A.al("Attempting to box non-Dart object.")
s={}
s[$.rG()]=a
p.error=s
p.stack=b.l(0)
r=this.a
r.call(r,p)
return p},
$S:127}
A.nG.prototype={
cA(a){if(a<=0||a>4294967296)throw A.c(A.qi(u.g+a))
return Math.random()*a>>>0},
fn(){return Math.random()}}
A.i8.prototype={
dU(a){var s,r,q,p,o,n,m,l=this,k=4294967296
do{s=a>>>0
a=B.c.a3(a-s,k)
r=a>>>0
a=B.c.a3(a-r,k)
q=(~s>>>0)+(s<<21>>>0)
p=q>>>0
r=(~r>>>0)+((r<<21|s>>>11)>>>0)+B.c.a3(q-p,k)>>>0
q=((p^(p>>>24|r<<8))>>>0)*265
s=q>>>0
r=((r^r>>>24)>>>0)*265+B.c.a3(q-s,k)>>>0
q=((s^(s>>>14|r<<18))>>>0)*21
s=q>>>0
r=((r^r>>>14)>>>0)*21+B.c.a3(q-s,k)>>>0
s=(s^(s>>>28|r<<4))>>>0
r=(r^r>>>28)>>>0
q=(s<<31>>>0)+s
p=q>>>0
o=B.c.a3(q-p,k)
q=l.a*1037
n=l.a=q>>>0
m=l.b*1037+B.c.a3(q-n,k)>>>0
l.b=m
n=(n^p)>>>0
l.a=n
o=(m^r+((r<<31|s>>>1)>>>0)+o>>>0)>>>0
l.b=o}while(a!==0)
if(o===0&&n===0)l.a=23063
l.b9()
l.b9()
l.b9()
l.b9()},
b9(){var s=this,r=s.a,q=4294901760*r,p=q>>>0,o=55905*r,n=o>>>0,m=n+p+s.b
r=m>>>0
s.a=r
s.b=B.c.a3(o-n+(q-p)+(m-r),4294967296)>>>0},
cA(a){var s,r,q,p=this
if(a<=0||a>4294967296)throw A.c(A.qi(u.g+a))
s=a-1
if((a&s)>>>0===0){p.b9()
return(p.a&s)>>>0}do{p.b9()
r=p.a
q=r%a}while(r-q+a>=4294967296)
return q},
fn(){var s,r=this
r.b9()
s=r.a
r.b9()
return((s&67108863)*134217728+(r.a&134217727))/9007199254740992}}
A.j_.prototype={}
A.fQ.prototype={}
A.fR.prototype={
ff(a,b){var s=new Uint8Array(16)
new Uint8Array(16)
B.r.fL(A.at(s,0,null),0,a)}}
A.j0.prototype={}
A.dE.prototype={}
A.aq.prototype={
aw(a,b){var s,r=this
if(b==null)return!1
if(r!==b)s=b instanceof A.aq&&A.ip(r)===A.ip(b)&&r.a===b.a&&r.b===b.b
else s=!0
return s},
gY(a){return B.a.gY(this.a)^B.c.gY(this.b)},
l(a){return"PageKey("+this.a+", "+this.b+")"}}
A.dF.prototype={
cY(a,b){var s=this.e
if(s==null)return
new A.fR(new A.fQ(A.pJ(s))).ff(a,b)},
bK(){var s,r,q=this,p=q.f
p===$&&A.b()
if(p)return
if(q.b==null)try{s=A.h6(q.a)
if(!s.aX())s.bX(!0)
q.b=s.iY(B.b8)}catch(r){q.b=null}},
a4(){var s=this,r=s.d
if(r!==-1)return r
r=s.f
r===$&&A.b()
if(r){r=s.r
return s.d=r.a===0?0:new A.aB(r,A.E(r).i("aB<1>")).j5(0,new A.mc())+1}s.bK()
r=s.b
if(r==null)return 0
r.iT()},
dJ(a,b){var s,r,q=this,p=q.f
p===$&&A.b()
if(p){s=q.r.h(0,a)
if(s!=null)B.j.aj(b,0,s)
else B.j.bC(b,0,b.length,0)
return}q.bK()
p=q.b
if(p==null){B.j.bC(b,0,b.length,0)
return}r=q.d
if(a>=(r===-1?q.d=p.iT().b_(0,q.c):r)){q.d=a+1
B.j.bC(b,0,b.length,0)
return}p=q.b
p.dR(a*q.c)
p.jl(b)
q.cY(a,b)},
cK(a,b){var s,r,q=this
if(a>=q.d)q.d=a+1
s=q.f
s===$&&A.b()
if(s){q.r.k(0,a,new Uint8Array(A.bx(b)))
return}q.bK()
s=q.b
if(s==null)return
s.dR(a*q.c)
if(q.e!=null){r=new Uint8Array(A.bx(b))
q.cY(a,r)
q.b.cI(r)}else s.cI(b)},
jf(a,b){var s,r,q,p,o,n=this,m=b.length,l=n.c,k=B.c.b_(m,l),j=a+k
if(j>=n.d)n.d=j
s=n.f
s===$&&A.b()
if(s){for(s=n.r,r=0;r<k;r=p){q=r*l
p=r+1
s.k(0,a+r,new Uint8Array(b.subarray(q,A.pg(q,p*l,m))))}return}n.bK()
m=n.b
if(m==null)return
m.dR(a*l)
if(n.e!=null){o=new Uint8Array(A.bx(b))
for(r=0;r<k;++r)n.cY(a+r,J.bm(B.j.gai(o),o.byteOffset+r*l,l))
n.b.cI(o)}else m.cI(b)},
c_(){var s=this.f
s===$&&A.b()
if(s)return
s=this.b
if(s!=null)s.c_()},
aW(){var s=this,r=s.f
r===$&&A.b()
if(r){s.r.v(0)
s.d=-1
return}r=s.b
if(r!=null){r.aW()
s.b=null}s.d=-1},
fA(a){var s,r,q=this
q.d=a
s=q.f
s===$&&A.b()
if(s){q.r.j7(0,new A.md(a))
return}q.bK()
s=q.b
if(s==null)return
s.h2()
r=s.d.jn(0,a*q.c)
A.al(A.oJ("truncate failed",s.a,r))}}
A.mc.prototype={
$2(a,b){return a>b?a:b},
$S:124}
A.md.prototype={
$2(a,b){return a>=this.a},
$S:123}
A.hu.prototype={}
A.hI.prototype={}
A.n6.prototype={}
A.cO.prototype={}
A.m0.prototype={
gab(){var s,r,q,p,o=this.at
if(o!=null)return o
s=t.M.a($.V.h(0,B.F))
if(s!=null)return s.b
for(o=this.Q,r=o.length,q=0;q<r;++q){p=o[q].b
if(p!=null)return p}return this.as.b},
sab(a){var s,r,q,p,o
this.at=a
s=t.M.a($.V.h(0,B.F))
if(s!=null)s.b=a
else{for(r=this.Q,q=r.length,p=0;p<q;++p){o=r[p]
if(o.b!=null){o.b=a
return}}this.as.b=a}},
gaI(){var s,r,q,p,o=t.M.a($.V.h(0,B.F))
if(o!=null)return o.c
for(s=this.Q,r=s.length,q=0;q<r;++q){p=s[q].c
if(p!=null)return p}return this.as.c},
saI(a){var s,r,q,p,o=t.M.a($.V.h(0,B.F))
if(o!=null)o.c=a
else{for(s=this.Q,r=s.length,q=0;q<r;++q){p=s[q]
if(p.c!=null){p.c=a
return}}this.as.c=a}},
ga5(){var s=t.M.a($.V.h(0,B.F))
if(s!=null)return s.a
return this.as.a},
sa5(a){var s=t.M.a($.V.h(0,B.F))
if(s!=null)s.a=a
else this.as.a=a},
ea(a,b){var s=this.f
if(s==null)return
new A.fR(new A.fQ(A.pJ(s))).ff(a,b)},
hc(){if(this.gaI()!=null)return
return},
fZ(a,b,c,d,e){var s,r,q,p,o,n=this
n.hc()
if(n.gaI()==null)return
s=new A.nn($.ov())
s.iq(a)
if(a===1){r=B.x.aB(B.o.bB(t.a.a(c)))
q=new DataView(new ArrayBuffer(4))
q.setUint32(0,r.length,!1)
s.T(0,J.oy(B.r.gai(q)))
s.T(0,r)}else if(a===2){p=n.w.I(d,new A.m1(d))
q=new DataView(new ArrayBuffer(8))
q.setUint32(0,p.length,!1)
q.setUint32(4,e,!1)
s.T(0,J.oy(B.r.gai(q)))
s.T(0,p)
s.T(0,t.p.a(c))
b.toString
s.T(0,b)}o=n.gaI()
o.toString
o.cI(s.j8())},
bW(a,b){var s,r,q,p,o,n=this,m=n.gab()
if(m==null||n.c==null)return
s=m.c
if(s.E(0,a))return
r=m.b.h(0,a)
q=r==null?null:r.a
if(q==null)q=new Uint8Array(4096)
if(n.f!=null){p=new Uint8Array(A.bx(q))
o=new Uint8Array(A.bx(b))
r=a.b
n.ea(r,p)
n.ea(r,o)}else{o=b
p=q}n.fZ(2,o,p,a.a,a.b)
s.T(0,a)},
j4(a){return},
c5(a){var s,r,q=this.ax,p=q.a++
q.b.k(0,p,B.b_)
q=q.c
s=t.S
r=A.tw(q,s)
q.T(0,p)
this.sa5(new A.lV(p,r))
p=t.N
q=t.L
p=new A.n6(A.o(p,s),A.o(q,t.h0),A.aD(q),A.o(p,t.fi))
p.d=a.dP()
this.sab(p)},
cl(){var s,r,q,p=this
if(p.ga5()!=null){s=p.ax
r=p.ga5().a
s.b.k(0,r,B.U)
s.c.S(0,r)
p.sa5(null)}p.gab()!=null
p.sab(null)
p.bb()
s=p.gaI()
if(s!=null){try{p.gaI().c_()
p.gaI().aW()}catch(q){}p.saI(null)}},
bE(a){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c=this
if(c.ga5()!=null){s=c.ax
r=c.ga5().a
s.b.k(0,r,B.b0)
s.c.S(0,r)
c.sa5(null)}q=c.gab()
if(q==null)return
for(s=q.b,s=new A.an(s,A.E(s).i("an<1,2>")).gJ(0),r=c.d;s.p();){p=s.d
o=p.a
n=p.b.a
if(r.F(o)){m=r.h(0,o)
B.j.aj(m.b,0,n)
m.x=m.w=null
m.d=!0}else c.a_(o.a).cK(o.b,n)}for(s=q.a,s=new A.an(s,A.E(s).i("an<1,2>")).gJ(0),n=A.E(r).i("aL<1>"),l=t.E;s.p();){p=s.d
k=p.a
j=p.b
i=c.a_(k)
if(c.be(k)>j){h=A.a([],l)
for(g=new A.aL(r,r.r,r.e,n);g.p();){f=g.d
if(f.a===k&&f.b>=j)h.push(f)}for(g=h.length,e=0;e<h.length;h.length===g||(0,A.n)(h),++e)r.S(0,h[e])
i.fA(j)}}s=q.d
if(s!=null){a.dL(s)
a.aE()}c.bb()
c.sab(null)
if(c.gaI()!=null){try{c.gaI().aW()}catch(d){}c.saI(null)}},
fe(a,b){var s,r,q,p,o,n,m,l,k,j,i,h=this.gab()
if(h==null)throw A.c(A.q("No active transaction for savepoint."))
s=A.o(t.N,t.S)
r=A.o(t.L,t.p)
for(q=this.r,q=new A.ao(q,q.r,q.e,A.E(q).i("ao<2>")),p=this.d;q.p();){o=q.d
n=o.a4()
m=o.a
s.k(0,m,n)
for(l=0;l<n;++l){k=new A.aq(m,l)
if(p.F(k))r.k(0,k,new Uint8Array(A.bx(p.h(0,k).b)))
else{j=new Uint8Array(4096)
o.dJ(l,j)
r.k(0,k,j)}}}for(q=h.a,q=new A.an(q,A.E(q).i("an<1,2>")).gJ(0);q.p();){i=q.d
s.I(i.a,new A.m4(i))}h.e.k(0,a.toLowerCase(),new A.hI(a,b.dP(),s,r))},
fs(a,b){var s,r,q,p,o,n,m=this,l=m.gab()
if(l==null)throw A.c(A.q("No active transaction for savepoint."))
s=l.e
r=s.h(0,a.toLowerCase())
if(r==null)throw A.c(A.q("Savepoint '"+a+"' not found."))
r.d.a0(0,new A.ma(m))
r.c.a0(0,new A.mb(m))
b.dL(r.b)
b.aE()
q=A.E(s).i("aB<1>")
p=A.r(new A.aB(s,q),q.i("F.E"))
o=B.b.ac(p,a.toLowerCase())
if(o!==-1)for(n=o+1;n<p.length;++n)s.S(0,p[n])
m.bb()},
j6(a){var s,r,q,p,o,n=this.gab()
if(n==null)throw A.c(A.q("No active transaction for savepoint."))
s=n.e
if(!s.F(a.toLowerCase()))throw A.c(A.q("Savepoint '"+a+"' not found."))
r=A.E(s).i("aB<1>")
q=A.r(new A.aB(s,r),r.i("F.E"))
p=B.b.ac(q,a.toLowerCase())
if(p!==-1)for(o=p;o<q.length;++o)s.S(0,q[o])},
hb(a){var s,r=this.gab()
if(r==null)return
s=r.a
if(!s.F(a))s.k(0,a,this.be(a))},
iA(a){var s,r,q,p,o,n,m=A.a([],t.E)
for(r=this.d,q=new A.aL(r,r.r,r.e,A.E(r).i("aL<1>"));q.p();){p=q.d
if(p.a===a)m.push(p)}for(q=m.length,o=0;o<m.length;m.length===q||(0,A.n)(m),++o)r.S(0,m[o])
s=this.r.S(0,a)
if(s!=null)try{s.aW()}catch(n){}},
bs(a,b){var s=this
if(s.gab()!=null){s.dc(new A.aq(a,b),s.C(a,b))
s.u(a,b,!1)}},
be(a){var s,r,q,p=this.a_(a).a4()
for(s=this.d,s=new A.aL(s,s.r,s.e,A.E(s).i("aL<1>"));s.p();){r=s.d
if(r.a===a){q=r.b+1
if(q>p)p=q}}return p},
dc(a,b){var s,r,q,p,o=this,n=o.gab()
if(n==null)return
s=o.ga5()
r=s==null?null:s.a
if(r==null)r=0
if(b.r===r)return
s=a.a
o.hb(s)
q=n.b
if(!q.F(a)){p=n.a
p.I(s,new A.m2(o,a))
s=p.h(0,s)
s.toString
if(a.b<s)q.k(0,a,new A.hu(new Uint8Array(A.bx(new Uint8Array(A.bx(b.b))))))}b.r=r},
a_(a){var s=this.r.I(a,new A.m8(this,a))
s.e=this.f
return s},
C(a,b){var s,r,q,p,o=this,n=new A.aq(a,b);++o.x
s=o.y
r=s.h(0,a)
s.k(0,a,b)
if(o.gab()==null&&r!=null&&b===r+1)o.ib(a,b+1)
s=o.d
if(s.F(n)){s=s.h(0,n)
s.toString
if(o.gab()!=null)o.dc(n,s);++s.e
o.e.S(0,n)
return s}q=o.a_(a)
p=A.qa(b,4096)
q.dJ(b,p.b)
if(o.gab()!=null)o.dc(n,p)
if(s.a>=o.a)o.ef()
p.e=1
s.k(0,n,p)
return p},
ib(a,b){A.th(new A.m3(this,a,b),t.P)},
u(a,b,c){var s,r=new A.aq(a,b),q=this.d.h(0,r)
if(q==null)return
if(c)q.d=!0
s=q.e
if(s>0){--s
q.e=s
if(s===0)this.e.T(0,r)}},
iV(a,b){var s=new A.aq(a,b),r=this.d.h(0,s)
if(r!=null&&r.d)this.bW(s,r.b)},
iU(){var s,r,q,p
for(s=this.d,s=new A.an(s,A.E(s).i("an<1,2>")).gJ(0);s.p();){r=s.d
q=r.a
p=r.b
if(p.d)this.bW(q,p.b)}s=this.gaI()
if(s!=null)s.c_()},
ef(){var s,r,q,p=this,o=p.e
if(o.a===0)return
s=o.gH(0)
o.S(0,s)
r=p.d.S(0,s)
if(r!=null&&r.d){q=p.r.h(0,s.a)
if(q!=null){o=r.b
p.bW(s,o)
q.cK(r.a,o)}}},
bb(){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3=this,a4=A.o(t.L,t.b7)
for(s=a3.d,s=new A.an(s,A.E(s).i("an<1,2>")).gJ(0);s.p();){r=s.d
q=r.b
if(q.d)a4.k(0,r.a,q)}if(a4.a===0)return
s=a4.$ti.i("aB<1>")
p=A.r(new A.aB(a4,s),s.i("F.E"))
B.b.aq(p,new A.m6())
o=A.aD(t.d9)
n=A.o(t.N,t.be)
for(s=p.length,m=0;m<p.length;p.length===s||(0,A.n)(p),++m){l=p[m]
J.ae(n.I(l.a,new A.m7()),l)}for(s=new A.an(n,n.$ti.i("an<1,2>")).gJ(0),q=a3.r;s.p();){r=s.d
k=r.a
j=r.b
i=q.h(0,k)
if(i==null)continue
o.T(0,i)
for(h=J.X(j),g=0;g<h.gt(j);g=e){f=g
for(;;){e=f+1
if(!(e<h.gt(j)&&h.h(j,e).b===h.h(j,f).b+1))break
f=e}if(f-g+1>1)for(d=g;d<=f;){c=d+255
c=c<f?c:f
b=c-d+1
a=b===256?$.pB():J.bm(B.j.gai($.pB()),0,b*4096)
for(a0=0;a0<b;++a0){l=h.h(j,d+a0)
a1=a4.h(0,l)
a2=a1.b
a3.bW(l,a2)
B.j.aj(a,a0*4096,a2)
a1.d=!1}i.jf(h.h(j,d).b,a)
d=c+1}else{l=h.h(j,g)
a1=a4.h(0,l)
a2=a1.b
a3.bW(l,a2)
i.cK(l.b,a2)
a1.d=!1}}}for(s=A.i7(o,o.r,o.$ti.c),q=s.$ti.c;s.p();){h=s.d;(h==null?q.a(h):h).c_()}},
fi(a){var s,r,q,p,o,n,m,l=this
l.bb()
s=l.d
r=A.E(s).i("aB<1>")
q=r.i("aJ<F.E>")
p=A.r(new A.aJ(new A.aB(s,r),new A.m5(a),q),q.i("F.E"))
for(r=p.length,q=l.e,o=0;o<p.length;p.length===r||(0,A.n)(p),++o){n=p[o]
s.S(0,n)
q.S(0,n)}m=l.r.S(0,a)
if(m!=null)m.aW()},
dv(){var s,r,q,p,o,n=this
n.z=!0
n.bb()
n.d.v(0)
n.e.v(0)
for(r=n.r,q=new A.ao(r,r.r,r.e,A.E(r).i("ao<2>"));q.p();)q.d.aW()
r.v(0)
for(r=n.Q,q=r.length,p=0;p<r.length;r.length===q||(0,A.n)(r),++p){s=r[p]
if(s.c!=null){try{s.c.aW()}catch(o){}s.c=null}}B.b.v(r)
r=n.as
q=r.c
if(q!=null){try{q.aW()}catch(o){}r.c=null}}}
A.m1.prototype={
$0(){return new Uint8Array(A.bx(B.x.aB(this.a)))},
$S:122}
A.m4.prototype={
$0(){return this.a.b},
$S:15}
A.ma.prototype={
$2(a,b){var s,r=this.a,q=r.d
if(q.F(a)){s=q.h(0,a)
B.j.aj(s.b,0,b)
s.x=s.w=null
s.d=!0}else r.a_(a.a).cK(a.b,b)},
$S:75}
A.mb.prototype={
$2(a,b){var s,r,q,p=this.a,o=p.a_(a)
if(o.a4()>b){s=A.a([],t.E)
p=p.d
p.a0(0,new A.m9(a,b,s))
for(r=s.length,q=0;q<s.length;s.length===r||(0,A.n)(s),++q)p.S(0,s[q])
o.fA(b)}},
$S:12}
A.m9.prototype={
$2(a,b){if(a.a===this.a&&a.b>=this.b)this.c.push(a)},
$S:121}
A.m2.prototype={
$0(){return this.a.be(this.b.a)},
$S:15}
A.m8.prototype={
$0(){var s=this.b,r=new A.dF(s,4096,A.o(t.S,t.p))
B.a.U(s,":memory:")
r.f=!0
return r},
$S:120}
A.m3.prototype={
$0(){var s,r,q,p,o,n,m,l,k
try{o=this.a
if(o.z)return
n=this.b
m=this.c
s=new A.aq(n,m)
l=o.d
if(l.F(s))return
r=o.a_(n)
q=r.a4()
if(m>=q)return
p=A.qa(m,4096)
r.dJ(m,p.b)
if(o.z){r.aW()
return}if(!l.F(s)){if(l.a>=o.a)o.ef()
p.e=0
l.k(0,s,p)
o.e.T(0,s)}}catch(k){}},
$S:11}
A.m6.prototype={
$2(a,b){var s=B.a.A(a.a,b.a)
if(s!==0)return s
return B.c.A(a.b,b.b)},
$S:118}
A.m7.prototype={
$0(){return A.a([],t.E)},
$S:106}
A.m5.prototype={
$1(a){return a.a===this.a},
$S:104}
A.dS.prototype={
cb(){return"TxStatus."+this.b}}
A.lV.prototype={}
A.lW.prototype={
aC(a,b,c,d){var s,r
if(a!==0){s=this.b.h(0,a)
if(s==null)s=B.U
if(s===B.b0)return!1
if(s===B.b_)if(a!==c)return!1
if(s===B.U)if(d.E(0,a))return!1}if(b===0)return!0
r=this.b.h(0,b)
if(r==null)r=B.U
if(r===B.b0)return!0
if(r===B.b_)if(b===c)return!1
else return!0
if(r===B.U){if(d.E(0,b))return!0
return!1}return!0}}
A.ci.prototype={
al(){var s=this,r=s.d,q=new Uint8Array(12+r.length),p=A.at(q,0,null)
p.$flags&2&&A.i(p,11)
p.setUint32(0,s.a,!1)
p.setUint32(4,s.b,!1)
p.setUint32(8,s.c,!1)
B.j.aj(q,12,r)
return q}}
A.B.prototype={
l(a){var s,r,q,p,o=this.b
if(o.length===0)return this.c
s=this.a
s=B.b.R(s," | ")+"\n"+(B.a.P("-",s.length*12)+"\n")
for(r=o.length,q=t.N,p=0;p<o.length;o.length===r||(0,A.n)(o),++p)s+=B.b.bc(o[p],new A.mG(),q).R(0," | ")+"\n"
return s.charCodeAt(0)==0?s:s},
gfu(){return this.b}}
A.mG.prototype={
$1(a){return a.l(0)},
$S:20}
A.h0.prototype={
cB(a){var s=this.x
s.h(0,a.toLowerCase())
s.h(0,"*")},
fF(a){return this.y.h(0,a.toLowerCase())},
iv(a){this.z.I(a.toLowerCase(),new A.iQ())},
br(){var s=0,r=A.b6(t.H),q=this,p,o
var $async$br=A.b7(function(a,b){if(a===1)return A.b3(b,r)
for(;;)switch(s){case 0:$.ex.v(0)
p=q.b
p===$&&A.b()
s=2
return A.ar(p.dF(),$async$br)
case 2:o=q.c
o===$&&A.b()
o.j4(p)
return A.b4(null,r)}})
return A.b5($async$br,r)},
b6(a){var s,r,q,p,o,n,m=this,l=a.toLowerCase(),k=m.r
if(k.F(l)){k=k.h(0,l)
k.toString
return k}s=m.b
s===$&&A.b()
r=s.e.h(0,l.toLowerCase())
if(r!=null){q=r.c.split(",").length
p=l}else{p="idx_"+l+"_id"
o=s.e.h(0,p.toLowerCase())
if(o!=null)q=o.c.split(",").length
else{p=l
q=1}}s=m.c
s===$&&A.b()
n=A.fU(s,m.a+"/"+p+".idx",q)
n.av()
k.k(0,l,n)
k.k(0,p,n)
return n},
L(){var s=0,r=A.b6(t.H),q=this,p,o,n
var $async$L=A.b7(function(a,b){if(a===1)return A.b3(b,r)
for(;;)switch(s){case 0:q.r.v(0)
p=q.c
p===$&&A.b()
p.dv()
p=q.w
if(p!=null){try{p.h2()
o=p.d.jk(0,0,-1)
A.al(A.oJ("unlock failed",p.a,o))
q.w.aW()}catch(m){}q.w=null}return A.b4(null,r)}})
return A.b5($async$L,r)}}
A.iQ.prototype={
$0(){return new A.fn(null,t.af)},
$S:91}
A.jJ.prototype={
hO(a){var s=a.toLowerCase()
return this.ay.I(s,new A.kR(this,s))},
h_(a,b){var s,r=a.length
if(r!==b.length)return!1
for(s=0;s<r;++s)if(a[s]!==b[s])return!1
return!0},
ct(a){return this.iB(a)},
iB(a){var s=0,r=A.b6(t.V),q,p=this,o,n
var $async$ct=A.b7(function(b,c){if(b===1)return A.b3(c,r)
for(;;)switch(s){case 0:n=p.cy
n===$&&A.b()
o=t.X
q=A.wk(new A.kT(p,a),A.a7([B.F,n],o,o),t.aM)
s=1
break
case 1:return A.b4(q,r)}})
return A.b5($async$ct,r)},
aA(a5){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0=this,a1="' created successfully.",a2="' already exists.",a3="' does not exist.",a4="' does not exist in table '"
$.eB=a0
if(a5 instanceof A.eX)throw A.c(new A.dN(a0.f.I(a5.a,new A.kp(a5)).$1(a0.c)))
if(a5 instanceof A.cc){s=a5.a
a0.a.y.k(0,s.toLowerCase(),a5)
return new A.B(A.a([],t.s),A.a([],t.F),"Macro '"+s+a1,B.f)}if(a5 instanceof A.eg){s=a5.a
a0.a.iv(s)
return new A.B(A.a([],t.s),A.a([],t.F),"Event stream '"+s+a1,B.f)}if(a5 instanceof A.el){s=a5.b
r=A.z(s).i("h<1,k>")
q=A.r(new A.h(s,new A.kq(a0),r),r.i("u.E"))
s=a5.a
p=a0.a.z.h(0,s.toLowerCase())
if(p!=null&&(p.c&4)===0)p.T(0,q)
return new A.B(A.a([],t.s),A.a([],t.F),"Event emitted to stream '"+s+"' successfully.",B.f)}if(a5 instanceof A.cB){s=a5.a
o=s.toLowerCase()
r=a0.a.b
r===$&&A.b()
if(r.x.F(o.toLowerCase()))A.al(A.q("Procedure '"+o+a2))
n=A.qh(s,a5.d)
r=a0.a.b
r===$&&A.b()
r.x.k(0,n.a.toLowerCase(),n)
r.aE()
return new A.B(A.a([],t.s),A.a([],t.F),"Procedure '"+s+a1,B.f)}if(a5 instanceof A.cA){s=a5.a
o=s.toLowerCase()
r=a0.a.b
r===$&&A.b()
if(r.y.F(o.toLowerCase()))A.al(A.q("Function '"+o+a2))
n=A.pV(s,a5.e)
r=a0.a.b
r===$&&A.b()
r.y.k(0,n.a.toLowerCase(),n)
r.aE()
return new A.B(A.a([],t.s),A.a([],t.F),"Function '"+s+a1,B.f)}if(a5 instanceof A.e9)return a0.hg(a5)
if(a5 instanceof A.ep){a0.aU()
s=a0.a.d
s===$&&A.b()
m=s.aM(a5.a).a6()
return new A.B(A.a(["QUERY PLAN"],t.s),A.a([A.a([new A.m(m)],t.K)],t.F),"Explain plan generated successfully.",B.f)}if(a5 instanceof A.d8)return a0.he(a5)
if(a5 instanceof A.dg)return a0.hl(a5)
if(a5 instanceof A.dc)return a0.hi(a5)
if(a5 instanceof A.bP)return a0.hd(a5)
if(a5 instanceof A.dd)return a0.d1(a5)
if(a5 instanceof A.f8)return a0.hy()
if(a5 instanceof A.f6)return a0.hx(a5)
if(a5 instanceof A.cH)return a0.ej(a5)
if(a5 instanceof A.dk)return a0.hn(a5)
if(a5 instanceof A.fj)return a0.hB(a5)
if(a5 instanceof A.aS)return a0.ek(a5)
if(a5 instanceof A.cS||a5 instanceof A.du||a5 instanceof A.dm||a5 instanceof A.di)return a0.hA(t.cf.a(a5))
if(a5 instanceof A.dH)return a0.hu(a5)
if(a5 instanceof A.e6)return a0.hf(a5)
if(a5 instanceof A.ew)return a0.ht(a5)
if(a5 instanceof A.fm)return a0.hD(a5)
if(a5 instanceof A.et)return a0.hr(a5)
if(a5 instanceof A.cC)return a0.ei(a5)
if(a5 instanceof A.f5)return a0.ei(new A.cC(a0.bI(a5.a)))
if(a5 instanceof A.f7){s=t.K
return new A.B(A.a(["schema_name"],t.s),A.a([A.a([new A.m("public")],s),A.a([new A.m("information_schema")],s)],t.F),"2 schemas found.",B.f)}if(a5 instanceof A.eP)return a0.hv(a5)
if(a5 instanceof A.fh)return a0.hz(a5)
if(a5 instanceof A.ej)return a0.hp(a5)
if(a5 instanceof A.ei)return a0.ho(a5)
if(a5 instanceof A.eh)return a0.hm(a5)
if(a5 instanceof A.e7){s=a0.a
r=s.c
r===$&&A.b()
s=s.b
s===$&&A.b()
r.c5(s)
return new A.B(A.a([],t.s),A.a([],t.F),"Transaction started.",B.f)}if(a5 instanceof A.eb){a0.aQ()
a0.aU()
s=a0.a.c
s===$&&A.b()
s.cl()
s=a0.a.c
s===$&&A.b()
s.bb()
return new A.B(A.a([],t.s),A.a([],t.F),"Transaction committed.",B.f)}if(a5 instanceof A.f0){B.b.v(a0.e)
a0.ce()
s=a0.a
r=s.c
r===$&&A.b()
s=s.b
s===$&&A.b()
r.bE(s)
a0.r.v(0)
return new A.B(A.a([],t.s),A.a([],t.F),"Transaction rolled back.",B.f)}if(a5 instanceof A.f2){a0.aQ()
s=a0.a
r=s.c
r===$&&A.b()
l=a5.a
s=s.b
s===$&&A.b()
r.fe(l,s)
return new A.B(A.a([],t.s),A.a([],t.F),"Savepoint "+l+" created.",B.f)}if(a5 instanceof A.f_){B.b.v(a0.e)
a0.ce()
s=a0.a
r=s.c
r===$&&A.b()
l=a5.a
s=s.b
s===$&&A.b()
r.fs(l,s)
a0.r.v(0)
return new A.B(A.a([],t.s),A.a([],t.F),"Rolled back to savepoint "+l+".",B.f)}if(a5 instanceof A.eW){s=a0.a.c
s===$&&A.b()
r=a5.a
s.j6(r)
return new A.B(A.a([],t.s),A.a([],t.F),"Savepoint "+r+" released.",B.f)}if(a5 instanceof A.df){s=a5.a
k=s.toLowerCase()
r=a0.a.b
r===$&&A.b()
if(r.d.F(k.toLowerCase()))A.al(A.q("Relationship '"+k+a2))
r=a0.a.b
r===$&&A.b()
l=a5.b
if(!r.c.F(l.toLowerCase()))A.al(A.q("Source table '"+l+a3))
r=a0.a.b
r===$&&A.b()
j=a5.c
if(!r.c.F(j.toLowerCase()))A.al(A.q("Destination table '"+j+a3))
r=a0.a.b
r===$&&A.b()
r=r.c.h(0,l.toLowerCase()).dx
r===$&&A.b()
i=a5.d
if(!B.b.E(r,i.toLowerCase()))A.al(A.q("Key column '"+i+a4+l+"'."))
r=a0.a.b
r===$&&A.b()
r=r.c.h(0,j.toLowerCase()).dx
r===$&&A.b()
h=a5.e
if(!B.b.E(r,h.toLowerCase()))A.al(A.q("Key column '"+h+a4+j+"'."))
r=a0.a.b
r===$&&A.b()
r.d.k(0,s.toLowerCase(),new A.dM(s,l,j,i,h))
return new A.B(A.a([],t.s),A.a([],t.F),"Relationship '"+s+a1,B.f)}if(a5 instanceof A.de)return a0.hk(a5)
if(a5 instanceof A.dh){s=a5.a
r=a5.d
g=A.qr(a5.c,a5.e,s,a5.w,r,a5.b)
l=a0.a.b
l===$&&A.b()
l.z.k(0,g.a.toLowerCase(),g)
l.aE()
return new A.B(A.a([],t.s),A.a([],t.F),"Trigger '"+s+"' created successfully on table '"+r+"'.",B.f)}if(a5 instanceof A.eN){f=a5.a.toLowerCase()
e=a0.cx.h(0,f)
if(e==null)A.al(A.q("Cursor '"+f+"' not declared."))
e.c=!0
s=a0.ek(e.b)
e.d=s
e.e=0
s=s.b.length!==0
e.f=s
r=a0.c
r.k(0,f+"%found",A.v(s?1:0))
r.k(0,f+"%notfound",A.v(e.f?0:1))
return new A.B(A.a([],t.s),A.a([],t.F),"Cursor '"+f+"' opened.",B.f)}if(a5 instanceof A.eq)return a0.hq(a5)
if(a5 instanceof A.ea){f=a5.a.toLowerCase()
e=a0.cx.h(0,f)
if(e!=null){e.c=!1
e.d=null
e.e=0
s=a0.c
s.S(0,f+"%found")
s.S(0,f+"%notfound")}return new A.B(A.a([],t.s),A.a([],t.F),"Cursor '"+f+"' closed.",B.f)}if(a5 instanceof A.dq)return a0.by()
if(a5 instanceof A.ev){s=a0.a.b
s===$&&A.b()
s.fG(a5.c,a5.b,a5.a)
return new A.B(A.a([],t.s),A.a([],t.F),"Grant succeeded.",B.f)}if(a5 instanceof A.eZ){s=a0.a.b
s===$&&A.b()
d=a5.c.toLowerCase()
c=a5.b.toLowerCase()
r=s.w
b=r.h(0,d)
if(b!=null){a=b.h(0,c)
if(a!=null){l=J.bc(a)
l.S(a,a5.a.toLowerCase())
if(l.ga9(a))b.S(0,c)
if(b.ga9(b))r.S(0,d)
s.aE()}}return new A.B(A.a([],t.s),A.a([],t.F),"Revoke succeeded.",B.f)}if(a5 instanceof A.f4){a0.b=a5.a
return new A.B(A.a([],t.s),A.a([],t.F),"User changed to "+a0.b+".",B.f)}if(a5 instanceof A.f3){s=a5.a
r=A.T(s.toLowerCase(),"'","")
o=B.a.V(A.T(r,'"',""))
if(o==="enableblockcompression"||o==="blockcompression")a0.a.f===$&&A.b()
else if(o==="enableautovacuum"||o==="autovacuum")a0.a.f===$&&A.b()
else if(o==="enableauditlogging"||o==="auditlogging")a0.a.f===$&&A.b()
else if(o==="enabledatamasking"||o==="datamasking")a0.a.f===$&&A.b()
else if(o==="enablecostbasedoptimizer"||o==="costbasedoptimizer"||o==="cbo")a0.a.f===$&&A.b()
else if(o==="enabletlsencryption"||o==="tlsencryption"||o==="tls")a0.a.f===$&&A.b()
else throw A.c(A.q("Unknown engine option: "+s))
r=A.a([],t.s)
l=A.a([],t.F)
j=a5.b?"ON":"OFF"
return new A.B(r,l,"Engine option "+s+" set to "+j+".",B.f)}if(a5 instanceof A.ef)return a0.bL(a5)
if(a5 instanceof A.fk)return a0.bM(a5)
throw A.c(A.q("Unsupported AST Node type: "+A.ip(a5).l(0)))},
by(){var s=0,r=A.b6(t.V),q,p=this,o,n,m,l,k,j,i,h,g,f
var $async$by=A.b7(function(a,b){if(a===1)return A.b3(b,r)
for(;;)switch(s){case 0:s=3
return A.ar(p.a.L(),$async$by)
case 3:if(A.dl(p.a.a).aX())for(n=A.a([],t.av),m=A.bL(),A.ta(void 1),A.u6(m,n,void 1,!1,!0),m=null.length,l=0;l<m;++l){o=null[l]
try{o.bx(!0)}catch(e){}}m=p.a.b
m===$&&A.b()
j=t.z
i=t.N
m.dL(A.a7(["tables",A.o(j,j),"relationships",A.o(j,j)],i,j))
s=4
return A.ar(p.a.br(),$async$by)
case 4:j=p.d
h=A.a6(j,!0,i)
B.b.v(j)
s=5
return A.ar(p.ct("CREATE TABLE depts (id INT, name TEXT);\nINSERT INTO depts VALUES (1, 'Engineering');\nINSERT INTO depts VALUES (2, 'Marketing');\n\nCREATE TABLE employees (id INT, name TEXT, dept_id INT);\nINSERT INTO employees VALUES (101, 'Alice', 1);\nINSERT INTO employees VALUES (102, 'Bob', 1);\nINSERT INTO employees VALUES (103, 'Charlie', 2);\n\nCREATE TABLE customers (id INT, info JSON);\nINSERT INTO customers VALUES (1, '{\"name\": \"Alice\", \"age\": 28, \"address\": {\"city\": \"New York\"}}');\nINSERT INTO customers VALUES (2, '{\"name\": \"Bob\", \"age\": 22, \"address\": {\"city\": \"Boston\"}}');\nINSERT INTO customers VALUES (3, '{\"name\": \"Charlie\", \"age\": 35, \"address\": {\"city\": \"Chicago\"}}');\n\nCREATE TABLE products (id INT, name TEXT, embedding VECTOR);\nINSERT INTO products VALUES (1, 'Tech Running Shoes', '[0.1, 0.85, -0.2]');\nINSERT INTO products VALUES (2, 'Quantum Physics Book', '[0.9, 0.1, 0.1]');\nINSERT INTO products VALUES (3, 'Classic Cotton T-Shirt', '[0.15, 0.7, -0.1]');\n\nCREATE RELATIONSHIP works_in FROM employees TO depts ON dept_id = id;\n\nDECLARE\n  counter INT := 0;\n  total INT := 0;\nBEGIN\n  DBMS_OUTPUT.PUT_LINE('Generating sample data successfully.');\n  WHILE counter < 10 LOOP\n    counter := counter + 1;\n    total := total + counter;\n    IF counter % 2 = 0 THEN\n      DBMS_OUTPUT.PUT_LINE('Counter ' || counter || ' is EVEN');\n    ELSE\n      DBMS_OUTPUT.PUT_LINE('Counter ' || counter || ' is ODD');\n    END IF;\n  END LOOP;\n  DBMS_OUTPUT.PUT_LINE('PL/SQL Cumulative Total: ' || total);\nEND;\n"),$async$by)
case 5:g=b
m=j.length
if(m!==0)for(l=0,i="=== GENERATION SUCCESSFUL ===\n1. Relational Tables created (depts, employees).\n2. NoSQL Table created (customers with info JSON).\n3. AI Vector Table created (products with embeddings).\n4. Graph Relationship created (works_in).\n5. PL/SQL logic executed.\n\nPL/SQL Output:\n";l<m;++l)i+="  "+j[l]+"\n"
else i="=== GENERATION SUCCESSFUL ===\n1. Relational Tables created (depts, employees).\n2. NoSQL Table created (customers with info JSON).\n3. AI Vector Table created (products with embeddings).\n4. Graph Relationship created (works_in).\n5. PL/SQL logic executed.\n"
j.$flags&1&&A.i(j,"insertAll",2)
A.tK(0,0,m,"index")
f=h.length
j.length=m+f
B.b.aF(j,f,j.length,j,0)
B.b.a8(j,0,f,h)
q=new A.B(A.a(["status"],t.s),A.a([A.a([new A.m("SUCCESS")],t.K)],t.F),i.charCodeAt(0)==0?i:i,g.d)
s=1
break
case 1:return A.b4(q,r)}})
return A.b5($async$by,r)},
hg(a){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e=this,d=e.a.b
d===$&&A.b()
n=a.a
s=d.x.h(0,n.toLowerCase())
if(s==null)throw A.c(A.q("Procedure '"+n+"' does not exist."))
d=a.b
m=A.z(d).i("h<1,k>")
l=A.r(new A.h(d,new A.jO(e),m),m.i("u.E"))
d=e.c
r=A.Z(d,t.N,t.r)
d.v(0)
k=0
for(;;){m=s.c
m===$&&A.b()
if(!(k<m.length))break
m=s.c
m===$&&A.b()
j=m[k]
i=k<l.length?l[k]:new A.d()
d.k(0,j.a,i);++k}q=null
try{m=s.d
m===$&&A.b()
h=m.length
g=0
for(;g<m.length;m.length===h||(0,A.n)(m),++g){p=m[g]
o=e.aA(p)
if(o instanceof A.ad){m=A.q("Asynchronous operations are not supported inside procedures.")
throw A.c(m)}if(o instanceof A.B)q=o}}catch(f){if(!(A.aV(f) instanceof A.dN))throw f}finally{d.v(0)
d.X(0,r)}d=q
d=d==null?null:d.a
if(d==null)d=A.a([],t.s)
m=q
m=m==null?null:m.b
if(m==null)m=A.a([],t.F)
return new A.B(d,m,"Procedure '"+n+"' executed successfully.",B.f)},
hl(a7){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1=this,a2=null,a3="' already exists.",a4=a7.a,a5=a4.toLowerCase(),a6=a1.a.b
a6===$&&A.b()
if(a6.c.F(a5.toLowerCase())){if(a7.e)return new A.B(A.a([],t.s),A.a([],t.F),"Table '"+a4+a3,B.f)
throw A.c(A.q("Table '"+a5+a3))}a6=a7.d
s=a6==null
if((s?a2:a6.a)!=null&&a7.b.length===0){r=a1.a.b
r===$&&A.b()
q=r.c.h(0,a6.a.toLowerCase().toLowerCase())
if(q!=null)for(r=q.b,p=a7.b,o=q.c,n=0;n<r.length;++n)p.push(new A.b_(r[n],o[n],!1,!1,a2,a2,!1,a2,a2,a2))}r=a7.b
m=B.b.b2(r,new A.jT())
p=A.z(r)
o=p.i("h<1,e>")
o=A.r(new A.h(r,new A.jU(),o),o.i("u.E"))
l=p.i("h<1,av>")
l=A.r(new A.h(r,new A.jV(),l),l.i("u.E"))
k=p.i("h<1,Q>")
j=k.i("u.E")
i=A.r(new A.h(r,new A.jW(),k),j)
h=A.r(new A.h(r,new A.jX(),k),j)
p=p.i("h<1,e?>")
g=p.i("u.E")
f=A.r(new A.h(r,new A.jY(),p),g)
e=A.r(new A.h(r,new A.jZ(),p),g)
k=A.r(new A.h(r,new A.k_(),k),j)
p=A.r(new A.h(r,new A.k0(),p),g)
j=a7.c
j=j==null?a2:j.b
g=s?a2:a6.a
d=s?a2:a6.b
c=A.bJ(a2,a2,p,o,k,i,e,f,l,h,a2,a2,m,!1,a4,j,a2,d,g,s?a2:a6.c,a2)
a6=c.CW
if(a6!=null){s=a1.a.b
s===$&&A.b()
q=s.c.h(0,a6.toLowerCase().toLowerCase())
if(q==null)throw A.c(A.q("Parent table '"+a6+"' does not exist."))
q.db.push(a4)
a6=a1.a.b
a6===$&&A.b()
a6.bp(q,!1)}a6=a1.a.b
a6===$&&A.b()
a6.bp(c,!0)
for(a6=r.length,s="idx_"+a5,p=s+"_",b=0;o=r.length,b<o;r.length===a6||(0,A.n)(r),++b){a=r[b]
if(a.c){o=a.a
a0=p+o.toLowerCase()
l=a1.a.b
l===$&&A.b()
if(!l.e.F(a0.toLowerCase())){l=a1.a.b
l===$&&A.b()
l.e.k(0,a0.toLowerCase(),new A.b9(a0,a4,o,a2))
l.r.v(0)
l.aE()}}}for(b=0;a6=r.length,b<a6;r.length===o||(0,A.n)(r),++b){a=r[b]
if(a.c||a.d){a6=a.a
a0=p+a6.toLowerCase()
l=a1.a.b
l===$&&A.b()
if(!l.e.F(a0.toLowerCase())){l=a1.a.b
l===$&&A.b()
l.e.k(0,a0.toLowerCase(),new A.b9(a0,a4,a6,a2))
l.r.v(0)
a1.a.b6(a0)}}}if(a6!==0&&r[0].a.toLowerCase()==="id"){a0=s+"_id"
a6=a1.a.b
a6===$&&A.b()
if(!a6.e.F(a0.toLowerCase())){a6=a1.a.b
a6===$&&A.b()
a6.f5(new A.b9(a0,a4,r[0].a,a2),!1)
a1.a.b6(a0)}}a6=A.a([],t.s)
s=A.a([],t.F)
r=m?" (optimized Columnar store)":" (Row store)"
return new A.B(a6,s,"Table '"+a4+"' created successfully"+r+".",B.f)},
hi(a){var s,r,q,p=null,o=a.a,n=o.toLowerCase(),m=this.a.b
m===$&&A.b()
if(m.c.F(n.toLowerCase()))throw A.c(A.q("Table '"+n+"' already exists."))
m=a.b
s=A.z(m)
r=s.i("h<1,e>")
r=A.r(new A.h(m,new A.jP(),r),r.i("u.E"))
s=s.i("h<1,av>")
m=A.r(new A.h(m,new A.jQ(),s),s.i("u.E"))
q=A.bJ(p,p,p,r,p,p,p,p,m,p,a.d,a.c,!1,!0,o,p,p,p,p,p,p)
m=this.a.b
m===$&&A.b()
m.bp(q,!0)
return new A.B(A.a([],t.s),A.a([],t.F),"Foreign table '"+o+"' created successfully.",B.f)},
hd(e2){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2,b3,b4,b5,b6,b7,b8,b9,c0,c1,c2,c3,c4,c5,c6,c7,c8,c9,d0,d1,d2,d3,d4,d5,d6,d7=this,d8=null,d9="' not found in table '",e0=e2.a.toLowerCase(),e1=d7.a.b
e1===$&&A.b()
j=e1.c.h(0,e0.toLowerCase())
if(j==null)throw A.c(A.q("Table '"+e0+"' does not exist."))
e1=e2.b
if(e1===B.b2){e1=e2.c
e1.toString
i=j.dx
i===$&&A.b()
h=e1.a
if(B.b.E(i,h.toLowerCase()))throw A.c(A.q("Column '"+h+"' already exists in table '"+e0+"'."))
i=j.a
g=A.r(j.b,t.N)
g.push(h)
f=A.r(j.c,t.q)
f.push(e1.b)
e=j.d
d=t.y
c=A.r(j.e,d)
c.push(e1.c)
b=A.r(j.f,d)
b.push(e1.d)
a=t.T
a0=A.r(j.r,a)
a0.push(e1.e)
a1=A.r(j.w,a)
a1.push(e1.f)
d=A.r(j.x,d)
d.push(e1.r)
a2=t.O
a3=A.r(j.y,a2)
a3.push(e1.w)
a2=A.r(j.z,a2)
a2.push(e1.x)
a4=j.Q
a=A.r(j.as,a)
a.push(e1.y)
a5=A.bJ(a2,a3,a,g,d,c,a1,a0,f,b,d8,d8,e,!1,i,d8,d8,d8,d8,d8,a4)
e1=d7.a.b
e1===$&&A.b()
e1.bp(a5,!1)
d7.ay.v(0)
d7.Q.v(0)
d7.as.v(0)
d7.CW.v(0)
d7.r.S(0,e0)
return new A.B(A.a([],t.s),A.a([],t.F),"Column '"+h+"' added to table '"+e0+"' successfully.",B.f)}else if(e1===B.b3){e1=e2.d
e1.toString
i=j.dx
i===$&&A.b()
s=B.b.ac(i,e1.toLowerCase())
if(J.az(s,-1))throw A.c(A.q("Column '"+e1+d9+e0+"'."))
h=j.e
if(h[s])throw A.c(A.q("Cannot drop primary key column '"+e1+"'."))
g=d7.a.b
g===$&&A.b()
a6=g.b5(e0,e1)
if(a6!=null){g=d7.a.b
g===$&&A.b()
f=a6.a
g.e.S(0,f.toLowerCase())
g.r.v(0)
r=A.h6(d7.a.a+"/"+f.toLowerCase()+".idx")
if(r.aX())try{r.bx(!1)}catch(a7){}}g=j.d
if(g){a8=j.b.length
for(a9=s,f=j.a;a9<a8;++a9){e=d7.a
d=e.c
d===$&&A.b()
d.fi(e.a+"/"+f+".col_"+a9)}b0=A.h6(d7.a.a+"/"+f+".col_"+A.D(s))
if(b0.aX())b0.bx(!1)
for(a9=s+1;a9<a8;++a9){b1=A.h6(d7.a.a+"/"+f+".col_"+A.D(a9))
if(b1.aX()){e=d7.a
A.ue(A.bL(),b1.b,e.a+"/"+f+".col_"+A.D(a9-1))}}}else{f=d7.a
e=f.c
e===$&&A.b()
d=j.a
b2=A.aO(e,f.a,d)
f=d7.a.c
f===$&&A.b()
e=b2.c+"/"+b2.b+".db"
b3=f.a_(e).a4()
q=A.a([],t.aj)
for(b4=0;b4<b3;++b4){f=d7.a.c
f===$&&A.b()
b5=f.C(e,b4)
b6=A.aT(b5)
for(b7=0;b7<b6;++b7){p=A.ab(b5,b7)
if(p!=null)try{o=A.aW(p)
n=A.a0(o.d,d8,d8)
if(s<J.O(n))J.pH(n,s)
m=A.p1(n)
J.ae(q,new A.ci(o.a,o.b,o.c,m))}catch(a7){l=A.a0(p,d8,d8)
if(s<J.O(l))J.pH(l,s)
k=A.p1(l)
J.ae(q,new A.ci(0,0,0,k))}}f=d7.a.c
f===$&&A.b()
f.u(e,b4,!1)}f=d7.a.c
f===$&&A.b()
f.fi(e)
b8=A.h6(e)
if(b8.aX())b8.bx(!1)
f=d7.a
e=f.c
e===$&&A.b()
b9=A.aO(e,f.a,d)
for(f=q,e=f.length,c0=0;c0<f.length;f.length===e||(0,A.n)(f),++c0)b9.iI(f[c0].al())
b9.bD()}c1=B.b.ac(i,e1.toLowerCase())
if(c1===-1)A.al(A.q("Column '"+e1+d9+j.a+"'."))
c2=A.a6(j.b,!0,t.N)
B.b.aN(c2,c1)
c3=A.a6(j.c,!0,t.q)
B.b.aN(c3,c1)
i=t.y
c4=A.a6(h,!0,i)
B.b.aN(c4,c1)
c5=A.a6(j.f,!0,i)
B.b.aN(c5,c1)
h=t.T
c6=A.a6(j.r,!0,h)
B.b.aN(c6,c1)
c7=A.a6(j.w,!0,h)
B.b.aN(c7,c1)
c8=A.a6(j.x,!0,i)
B.b.aN(c8,c1)
i=t.O
c9=A.a6(j.y,!0,i)
B.b.aN(c9,c1)
d0=A.a6(j.z,!0,i)
B.b.aN(d0,c1)
a5=A.bJ(d0,c9,d8,c2,c8,c4,c7,c6,c3,c5,d8,d8,g,!1,j.a,d8,d8,d8,d8,d8,j.Q)
g=d7.a.b
g===$&&A.b()
g.bp(a5,!1)
d7.ay.v(0)
d7.Q.v(0)
d7.as.v(0)
d7.CW.v(0)
d7.r.S(0,e0)
return new A.B(A.a([],t.s),A.a([],t.F),"Column '"+e1+"' dropped from table '"+e0+"' successfully.",B.f)}else if(e1===B.b4){e1=e2.e
e1.toString
i=e2.f
i.toString
h=j.dx
h===$&&A.b()
c1=B.b.ac(h,e1.toLowerCase())
if(c1===-1)A.al(A.q("Column '"+e1+d9+j.a+"'."))
c2=A.a6(j.b,!0,t.N)
c2[c1]=i
h=j.a
g=j.c
f=j.d
e=j.e
d=j.f
c=j.r
b=j.w
a=j.x
a0=j.y
a1=j.z
a2=j.Q
a3=j.as
a4=j.at
d1=j.ax
d2=j.ay
d3=j.ch
d4=j.CW
d5=j.cx
d6=j.cy
a5=A.bJ(a1,a0,a3,c2,a,e,b,c,g,d,d2,d1,f,a4,h,d3,j.db,d5,d4,d6,a2)
a2=d7.a.b
a2===$&&A.b()
a2.bp(a5,!1)
d7.ay.v(0)
d7.Q.v(0)
d7.as.v(0)
d7.CW.v(0)
d7.r.S(0,e0)
return new A.B(A.a([],t.s),A.a([],t.F),"Column '"+e1+"' renamed to '"+i+"' successfully in table '"+e0+"'.",B.f)}else if(e1===B.b5){e1=e2.r
e1.toString
i=e2.w
i.toString
h=j.dx
h===$&&A.b()
c1=B.b.ac(h,e1.toLowerCase())
if(c1===-1)A.al(A.q("Column '"+e1+d9+j.a+"'."))
c3=A.a6(j.c,!0,t.q)
c3[c1]=i
i=j.a
h=j.b
g=j.d
f=j.e
e=j.f
d=j.r
c=j.w
b=j.x
a=j.y
a0=j.z
a1=j.Q
a2=j.as
a3=j.at
a4=j.ax
d1=j.ay
d2=j.ch
d3=j.CW
d4=j.cx
d5=j.cy
a5=A.bJ(a0,a,a2,h,b,f,c,d,c3,e,d1,a4,g,a3,i,d2,j.db,d4,d3,d5,a1)
a1=d7.a.b
a1===$&&A.b()
a1.bp(a5,!1)
d7.ay.v(0)
d7.Q.v(0)
d7.as.v(0)
d7.CW.v(0)
d7.r.S(0,e0)
return new A.B(A.a([],t.s),A.a([],t.F),"Column '"+e1+"' type altered successfully in table '"+e0+"'.",B.f)}else throw A.c(A.q("Unsupported ALTER TABLE action."))},
hk(a){var s,r,q=a.b,p=q.toLowerCase(),o=this.a.b
o===$&&A.b()
s=o.c.h(0,p.toLowerCase())
if(s==null)throw A.c(A.q("Table '"+p+"' does not exist."))
o=s.Q
if(B.b.b2(o,new A.jS(a)))throw A.c(A.q("Policy '"+a.a+"' already exists on table '"+q+"'."))
r=a.a
B.b.T(o,new A.bt(r,a.c))
return new A.B(A.a([],t.s),A.a([],t.F),"Policy '"+r+"' created successfully on table '"+q+"'.",B.f)},
d2(a,a0,a1){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c=this.c,b=A.Z(c,t.N,t.r)
for(k=a0.b,j=0;j<k.length;++j){i=k[j]
c.k(0,"new."+i.toLowerCase(),a1[j])
c.k(0,"new."+i,a1[j])}try{h=a.r
h===$&&A.b()
g=h.length
f=this.f
e=0
for(;e<h.length;h.length===g||(0,A.n)(h),++e){s=h[e]
r=new A.d()
if(s.c!=null){d=s.c
d.toString
q=f.I(d,new A.kB(s))
r=q.$1(c)}c.k(0,s.a,r)}h=a.w
h===$&&A.b()
g=h.length
e=0
for(;e<h.length;h.length===g||(0,A.n)(h),++e){p=h[e]
this.aA(p)}for(o=0;o<k.length;++o){n=k[o]
m="new."+n.toLowerCase()
l="new."+A.D(n)
if(c.F(m)){h=o
g=c.h(0,m)
g.toString
a1[h]=g}else if(c.F(l)){h=o
g=c.h(0,l)
g.toString
a1[h]=g}}}finally{c.v(0)
c.X(0,b)}},
hq(a){var s,r,q,p,o=a.a.toLowerCase(),n=this.cx.h(0,o)
if(n==null||!n.c||n.d==null)throw A.c(A.q("Cursor '"+o+"' is not open."))
s=n.e
r=n.d.b
if(s<r.length){n.e=s+1
q=r[s]
s=this.c
r=a.b
p=0
for(;;){if(!(p<r.length&&p<q.length))break
s.k(0,r[p],q[p]);++p}n.f=!0
s.k(0,o+"%found",A.v(1))
s.k(0,o+"%notfound",A.v(0))}else{n.f=!1
s=this.c
s.k(0,o+"%found",A.v(0))
s.k(0,o+"%notfound",A.v(1))}return new A.B(A.a([],t.s),A.a([],t.F),"Fetched from cursor '"+o+"'.",B.f)},
bL(a){return this.hh(a)},
hh(a){var s=0,r=A.b6(t.V),q,p,o,n,m
var $async$bL=A.b7(function(b,c){if(b===1)return A.b3(c,r)
for(;;)switch(s){case 0:o=a.a
n=o+"_db"
m=A.dl(n)
if(!m.aX())m.bX(!0)
p=A.oE(n,null)
s=3
return A.ar(p.br(),$async$bL)
case 3:s=4
return A.ar(p.L(),$async$bL)
case 4:q=new A.B(A.a([],t.s),A.a([],t.F),"Database '"+o+"' created successfully.",B.f)
s=1
break
case 1:return A.b4(q,r)}})
return A.b5($async$bL,r)},
bM(a){return this.hC(a)},
hC(a){var s=0,r=A.b6(t.V),q,p=this,o,n,m,l,k
var $async$bM=A.b7(function(b,c){if(b===1)return A.b3(c,r)
for(;;)switch(s){case 0:l=a.a
k=l+"_db"
if(!A.dl(k).aX())throw A.c(A.q("Database '"+l+"' does not exist."))
s=3
return A.ar(p.a.L(),$async$bM)
case 3:o=A.oE(k,null)
s=4
return A.ar(o.br(),$async$bM)
case 4:p.a=o
p.r.v(0)
p.w.v(0)
p.x.v(0)
p.y.v(0)
p.z.v(0)
p.Q.v(0)
p.as.v(0)
p.at.v(0)
p.ay.v(0)
p.ch.v(0)
p.CW.v(0)
p.f.v(0)
n=p.a.c
n===$&&A.b()
m=new A.cO()
n.Q.push(m)
p.cy=m
q=new A.B(A.a([],t.s),A.a([],t.F),"Switched to database '"+l+"'.",B.f)
s=1
break
case 1:return A.b4(q,r)}})
return A.b5($async$bM,r)},
e4(a,b,c){var s,r,q,p,o,n="Type mismatch for column '"
if(a instanceof A.d||a.gae()===b)return a
if(b===B.L&&a instanceof A.p)return new A.j(a.a)
if(b===B.M&&a instanceof A.m)try{s=B.o.ag(a.a)
return new A.M(s,null)}catch(r){s=A.q(n+c+"'. Expected "+b.l(0)+", found "+B.t.l(0)+".")
throw A.c(s)}if(b===B.W&&a instanceof A.m){q=A.vp(a.a)
if(q!=null)return q
throw A.c(A.q(n+c+"'. Expected "+b.l(0)+", found "+B.t.l(0)+"."))}if(b===B.a6){if(a instanceof A.p)return new A.aG(a.a!==0)
if(a instanceof A.m){s=a.a
return new A.aG(s.toLowerCase()==="true"||s==="1")}}if(b===B.a7&&a instanceof A.m)return new A.bp(a.a)
if(b===B.a8&&a instanceof A.m){p=A.bA(a.a)
if(p!=null)return new A.bo(p)}if(b===B.a9)if(a instanceof A.m)return new A.b0(new Uint8Array(A.bx(B.x.aB(a.a))))
if(b===B.aa){if(a instanceof A.p)return new A.a8(a.a)
if(a instanceof A.j)return new A.a8(a.a)
if(a instanceof A.m){o=A.aH(a.a)
if(o!=null)return new A.a8(o)}}throw A.c(A.q(n+c+"'. Expected "+b.l(0)+", found "+a.gae().l(0)+"."))},
ej(j3){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2,b3,b4,b5,b6,b7,b8,b9,c0,c1,c2,c3,c4,c5,c6,c7,c8,c9,d0,d1,d2,d3,d4,d5,d6,d7,d8,d9,e0,e1,e2,e3,e4,e5,e6,e7,e8,e9,f0,f1,f2,f3,f4,f5,f6,f7,f8,f9,g0,g1,g2,g3,g4,g5,g6,g7,g8,g9,h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,i0,i1,i2,i3,i4,i5,i6,i7,i8=this,i9=null,j0="euclidean",j1={},j2=j3.c
if(j2!=null&&j2.length>1){for(b1=j2.length,b2=j3.a,b3=j3.d,b4=j3.e,b5=j3.f,b6=j3.r,b7=j3.w,b8=0,b9=0;b9<j2.length;j2.length===b1||(0,A.n)(j2),++b9){i8.ej(new A.cH(b2,j2[b9],i9,b3,b4,b5,b6,b7));++b8}return new A.B(A.a([],t.s),A.a([],t.F),""+b8+" rows inserted into table '"+b2+"'.",B.f)}j2=i8.a.b
j2===$&&A.b()
b1=j3.a
if(!j2.c0(i8.b,b1,"insert"))throw A.c(A.q("Permission denied: INSERT privilege required on table '"+b1+"' for user '"+i8.b+"'."))
c0=j1.a=i8.Q.I(j3,new A.kb(i8,j3))
c1=c0.a.toLowerCase()
j2=j3.b
b2=J.X(j2)
b3=b2.gt(j2)
b4=c0.b.length
if(b3!==b4)throw A.c(A.q("Column count mismatch. Expected "+b4+" values, found "+b2.gt(j2)+"."))
c2=b2.gt(j2)
c3=i8.ax
if(c3==null||c3.length!==c2){c3=A.a9(c2,new A.d(),!1,t.r)
i8.ax=c3}b3=i8.at
if(b3.F(j3))c4=b3.h(0,j3)
else{c5=A.a([],t.t)
j2=b2.gJ(j2)
for(;;){if(!j2.p()){c6=!0
break}b2=j2.gD()
if(b2 instanceof A.aR)c5.push(b2.c)
else{c6=!1
break}}c4=c6?c5:i9
b3.k(0,j3,c4)}if(!(c4!=null)){c7=i8.as.I(j3,new A.kc(j3))
for(j2=J.X(c7),b2=i8.c,c8=0;c8<c2;++c8){c9=j2.h(c7,c8).$1(b2)
b3=j1.a
c3[c8]=i8.e4(c9,b3.c[c8],b3.b[c8])}}j2=j1.a
if(j2.db.length!==0&&j2.ch!=null){b2=j2.dx
b2===$&&A.b()
d0=B.b.ac(b2,j2.ch.toLowerCase())
if(d0===-1)throw A.c(A.q("Partition column "+A.D(j1.a.ch)+" not found in table "+c1+"."))
c9=c3[d0]
d1=c9.l(0)
if(c9 instanceof A.m)d1=c9.a
j2=j1.a.db
b2=j2.length
b9=0
for(;;){if(!(b9<j2.length)){d2=!1
break}d3=j2[b9]
b3=i8.a.b
b3===$&&A.b()
d4=b3.c.h(0,d3.toLowerCase().toLowerCase())
if(d4!=null&&d4.cx!=null&&d4.cy!=null){b3=d4.cx
b3.toString
if(d1===b3)b3=0
else b3=d1<b3?-1:1
if(b3>=0){b3=d4.cy
b3.toString
if(d1===b3)b3=0
else b3=d1<b3?-1:1
b3=b3<=0}else b3=!1
if(b3){j1.a=d4
c1=d4.a.toLowerCase()
d2=!0
break}}j2.length===b2||(0,A.n)(j2);++b9}if(!d2)throw A.c(A.q("No matching partition found for row in partitioned table '"+c1+"'. Partition value: '"+d1+"'"))}j2=i8.a.b
j2===$&&A.b()
d5=j2.cL(c1,"BEFORE","INSERT")
for(j2=d5.length,b9=0;b9<d5.length;d5.length===j2||(0,A.n)(d5),++b9)i8.d2(d5[b9],j1.a,c3)
j2=j1.a.fr
j2===$&&A.b()
if(j2){i8.aU()
s=null
r=null
q=null
p=!1
o=null
n=null
for(m=0,j2=i8.r,b2=t.n;b3=m,b4=j1.a,b5=b4.b,b3<b5.length;++m){b3=b4.e
if(b3[m]||b4.f[m]){l=c3[m]
if(l instanceof A.d){if(b3[m])throw A.c(A.q("Primary key column '"+b5[m]+"' cannot be NULL."))
continue}b3=i8.a.b
b3===$&&A.b()
d6=b3.b5(c1,b5[m])
if(d6!=null)b3=l instanceof A.p||l instanceof A.j
else b3=!1
if(b3){if(l instanceof A.p)d7=l.a
else d7=l instanceof A.j?l.a:i9
d8=d7!=null
if(d8){k=j2.I(c1,new A.kd(j1,i8))
d9=i8.a.b6(d6.a).cP(A.a([d7],b2),A.a([d7],b2))
for(b3=d9.length,b9=0;b9<d9.length;d9.length===b3||(0,A.n)(d9),++b9){j=d9[b9]
b4=i8.a.c
b4===$&&A.b()
b5=k
i=A.ab(b4.C(b5.c+"/"+b5.b+".db",j.a),j.b)
if(i!=null)try{h=A.aW(i)
b4=i8.a.c
b4===$&&A.b()
g=b4.ga5()
b4=i8.a.c
b4===$&&A.b()
f=b4.ax
b4=g
e0=b4==null?i9:b4.a
e=e0==null?0:e0
b4=g
e1=b4==null?i9:b4.b
d=e1==null?B.u:e1
if(f.aC(h.a,h.b,e,d)){p=!0
s=j.a
r=j.b
q=A.a0(h.d,i9,i9)
o=j1.a.b[m]
n=l
b3=i8.a.c
b3===$&&A.b()
b4=k
b3.u(b4.c+"/"+b4.b+".db",j.a,!1)
break}}catch(e2){p=!0
s=j.a
r=j.b
q=A.a0(i,i9,i9)
o=j1.a.b[m]
n=l
b3=i8.a.c
b3===$&&A.b()
b4=k
b3.u(b4.c+"/"+b4.b+".db",j.a,!1)
break}b4=i8.a.c
b4===$&&A.b()
b5=k
b4.u(b5.c+"/"+b5.b+".db",j.a,!1)}}}else d8=!1
if(!d8&&!p){e3=j2.I(c1,new A.kg(j1,i8))
b3=i8.a.c
b3===$&&A.b()
b4=e3.c+"/"+e3.b+".db"
e4=b3.a_(b4).a4()
for(e5=0;e5<e4;++e5){b3=i8.a.c
b3===$&&A.b()
e6=b3.C(b4,e5)
e7=A.aT(e6)
for(e8=0;e8<e7;++e8){c=A.ab(e6,e8)
if(c!=null){b=null
try{a=A.aW(c)
b3=i8.a.c
b3===$&&A.b()
a0=b3.ga5()
b3=i8.a.c
b3===$&&A.b()
a1=b3.ax
b3=a0
e0=b3==null?i9:b3.a
a2=e0==null?0:e0
b3=a0
e1=b3==null?i9:b3.b
a3=e1==null?B.u:e1
if(a1.aC(a.a,a.b,a2,a3))b=A.a0(a.d,i9,i9)}catch(e2){b=A.a0(c,i9,i9)}if(b==null)continue
if(m<J.O(b))if(J.Y(b,m).A(0,l)===0){p=!0
s=e5
r=e8
q=b
o=j1.a.b[m]
n=l
b3=i8.a.c
b3===$&&A.b()
b3.u(b4,e5,!1)
break}}}b3=i8.a.c
b3===$&&A.b()
b3.u(b4,e5,!1)
if(p)break}}if(p)break}}if(p){if(j3.f)return new A.B(A.a([],t.s),A.a([],t.F),"0 rows inserted (conflict ignored).",B.f)
b3=j3.e
if((b3||j3.w!=null)&&s!=null&&r!=null&&q!=null){k=j2.I(c1,new A.kh(j1,i8))
j2=i8.a.c
j2===$&&A.b()
g=j2.ga5()
e=g==null?i9:g.a
if(e==null)e=1
j2=j3.w
if(j2!=null&&j2.a!==0){b4=t.r
e9=A.a6(q,!0,b4)
f0=A.o(t.N,b4)
for(b4=c1+".",f1=0;b5=j1.a.b,f1<b5.length;++f1){f2=b5[f1].toLowerCase()
f0.k(0,f2,J.Y(q,f1))
f0.k(0,b4+f2,J.Y(q,f1))
f0.k(0,"excluded."+f2,c3[f1])}j2.a0(0,new A.ki(j1,i8,f0,e9))
f3=e9}else f3=c3
k.cn(s,r,e)
f4=k.dC(f3,e)
j2=i8.a.b
j2===$&&A.b()
for(j2=J.as(j2.bf(c1)),b4=i8.z,b5=t.s,b6=t.e,b7=b6.i("u.E"),f5=i8.e,f6=f4.a,f7=f4.b;j2.p();){f8=j2.gD()
f9=b4.I(f8,new A.kj(f8))
f8=f8.c
g0=A.r(new A.h(A.a(f8.split(","),b5),new A.kk(),b6),b7)
g1=A.a([],b2)
for(g2=g0.length,b9=0;b9<g0.length;g0.length===g2||(0,A.n)(g0),++b9){f2=g0[b9]
g3=B.b.c1(j1.a.b,new A.kl(f2))
if(g3!==-1){g4=f3[g3]
if(g4 instanceof A.p)d7=g4.a
else d7=g4 instanceof A.j?g4.a:0
g1.push(d7)}}if(g1.length!==0)f5.push(new A.bk(f9,c1,f8,g1,f6,f7))}i8.aU()
i8.aQ()
j2=A.a([],b5)
b2=A.a([],t.F)
return new A.B(j2,b2,b3?"1 row replaced into table '"+b1+"'.":"1 row updated (on conflict).",B.f)}throw A.c(A.q("Unique constraint violation: value '"+J.x(n)+"' already exists in unique column '"+A.D(o)+"'."))}}j2=j1.a
b1=j2.dy
b1===$&&A.b()
if(b1){for(j2=t.n,b1=i8.r,m=0;b2=j1.a,m<b2.b.length;++m){g5=b2.r[m]
g6=b2.w[m]
if(g5!=null&&g6!=null){l=c3[m]
if(l instanceof A.d)continue
b2=i8.a.b
b2===$&&A.b()
g7=b2.c.h(0,g5.toLowerCase())
if(g7==null)throw A.c(A.q("Foreign key constraint error: referenced table '"+g5+"' does not exist."))
b2=g7.dx
b2===$&&A.b()
g8=B.b.ac(b2,g6.toLowerCase())
if(g8===-1)throw A.c(A.q("Foreign key constraint error: referenced column '"+g6+"' does not exist in table '"+g5+"'."))
b2=i8.a.b
b2===$&&A.b()
d6=b2.b5(g5,g6)
if(d6!=null)b2=l instanceof A.p||l instanceof A.j
else b2=!1
g9=!1
if(b2){if(l instanceof A.p)d7=l.a
else d7=l instanceof A.j?l.a:i9
if(d7!=null)g9=i8.a.b6(d6.a).bj(A.a([d7],j2))!=null}if(!g9){h0=b1.I(g5.toLowerCase(),new A.km(i8,g7))
b2=i8.a.c
b2===$&&A.b()
b3=h0.c+"/"+h0.b+".db"
e4=b2.a_(b3).a4()
for(d2=!1,e5=0;e5<e4;++e5){b2=i8.a.c
b2===$&&A.b()
e6=b2.C(b3,e5)
e7=A.aT(e6)
for(e8=0;e8<e7;++e8){a4=A.ab(e6,e8)
if(a4!=null){a5=null
try{a6=A.aW(a4)
b2=i8.a.c
b2===$&&A.b()
a7=b2.ga5()
b2=i8.a.c
b2===$&&A.b()
a8=b2.ax
b2=a7
e=b2==null?i9:b2.a
a9=e==null?0:e
b2=a7
d=b2==null?i9:b2.b
b0=d==null?B.u:d
if(a8.aC(a6.a,a6.b,a9,b0))a5=A.a0(a6.d,i9,i9)}catch(e2){a5=A.a0(a4,i9,i9)}if(a5==null)continue
if(g8<J.O(a5))if(J.Y(a5,g8).A(0,l)===0){d2=!0
break}}}b2=i8.a.c
b2===$&&A.b()
b2.u(b3,e5,!1)
if(d2)break}if(!d2)throw A.c(A.q("Foreign key constraint violation: value '"+l.l(0)+"' in column '"+j1.a.b[m]+"' does not exist in referenced column '"+g5+"("+g6+")'."))}}}j2=b2}if(j2.d){i8.w.I(c1,new A.kn(j1,i8)).iK(c3)
h1=0
h2=0}else{k=i8.r.I(c1,new A.ke(j1,i8))
j2=i8.a.c
j2===$&&A.b()
j2=j2.ga5()
e=j2==null?i9:j2.a
h3=k.dC(c3,e==null?0:e)
h1=h3.a
h2=h3.b}j2=i8.a.b
j2===$&&A.b();++j2.bg(c1).a
j2=i8.a.b
j2===$&&A.b()
for(j2=J.as(j2.bf(c1)),b1=i8.z,b2=t.n,b3=i8.e,b4=c3.length,b5=t.G,b6=t.S,b7=t.gB,f5=t.D,f6=t.N,f7=t.eb;j2.p();){f8=j2.gD()
f9=b1.I(f8,new A.kf(f8))
g2=f8.c
h4=g2.split(",")
h5=A.a([],b2)
h7=h4.length
b9=0
for(;;){h6=!1
if(!(b9<h4.length)){h6=!0
break}h8=B.a.V(h4[b9])
h9=j1.a.dx
h9===$&&A.b()
g3=B.b.ac(h9,h8.toLowerCase())
if(g3===-1)break
i0=c3[g3]
if(i0 instanceof A.p)d7=i0.a
else if(i0 instanceof A.j)d7=i0.a
else if(i0 instanceof A.m){h8=i0.a
i1=A.aH(h8)
if(i1!=null)d7=i1
else{for(h9=h8.length,i2=0,i3=0;i3<h9;++i3)i2=B.c.a7(i2*31+h8.charCodeAt(i3),9007199254740991)
d7=i2}}else d7=i9
if(d7==null)break
h5.push(d7)
h4.length===h7||(0,A.n)(h4);++b9}h7=f8.d
if(h7==="fts"){h7=j1.a.dx
h7===$&&A.b()
g3=B.b.ac(h7,g2.toLowerCase())
if(g3!==-1&&g3<b4){l=c3[g3]
if(l instanceof A.m){i4=new A.h9(i8.a.a+"/"+f8.a.toLowerCase()+".fts",A.o(f6,f7))
i4.av()
i4.ir(l.a,h1,h2)}}}else{h8=h7==null
if(h8)h9=i9
else h9=A.T(h7,"_","").toLowerCase()
if((h9==null?"":h9)!=="ivf"){if(h8)h8=i9
else h8=A.T(h7,"_","").toLowerCase()
h8=(h8==null?"":h8)==="ivfflat"}else h8=!0
if(h8){h7=j1.a.dx
h7===$&&A.b()
g3=B.b.ac(h7,g2.toLowerCase())
if(g3!==-1&&g3<b4){l=c3[g3]
if(l instanceof A.a5){i5=new A.hh(i8.a.a+"/"+f8.a.toLowerCase()+".ivf_flat",!1,j0,A.a([],b5),A.o(b6,b7),A.a([],f5))
i5.av()
i5.b4(l,h1,h2)
i5.bh()}}}else if(h7==="hnsw"){h7=j1.a.dx
h7===$&&A.b()
g3=B.b.ac(h7,g2.toLowerCase())
if(g3!==-1&&g3<b4){l=c3[g3]
if(l instanceof A.a5){i6=A.oN(!1,i8.a.a+"/"+f8.a.toLowerCase()+".hnsw",j0)
i6.av()
i6.b4(l,h1,h2)
i6.bh()}}}else if(h6&&h5.length===h4.length)b3.push(new A.bk(f9,c1,g2.toLowerCase(),h5,h1,h2))}}j2=i8.a.b
j2===$&&A.b()
i7=j2.cL(c1,"AFTER","INSERT")
for(j2=i7.length,b9=0;b9<i7.length;i7.length===j2||(0,A.n)(i7),++b9)i8.d2(i7[b9],j1.a,c3)
i8.a.cB(c1)
return new A.B(A.a([],t.s),A.a([],t.F),"1 row inserted successfully.",B.f)},
hn(e1){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2,b3,b4,b5,b6,b7,b8,b9,c0,c1,c2,c3,c4,c5,c6,c7,c8,c9,d0,d1,d2,d3,d4,d5,d6,d7,d8=this,d9=null,e0=d8.a.b
e0===$&&A.b()
c7=e1.a
if(!e0.c0(d8.b,c7,"delete"))throw A.c(A.q("Permission denied: DELETE privilege required on table '"+c7+"' for user '"+d8.b+"'."))
d8.aU()
s=c7.toLowerCase()
e0=d8.a.b
e0===$&&A.b()
r=e0.c.h(0,s.toLowerCase())
if(r==null)throw A.c(A.q("Table '"+A.D(s)+"' does not exist."))
if(r.d)throw A.c(A.q("Deletes are not supported on columnar tables."))
e0=d8.a.c
e0===$&&A.b()
q=e0.gab()!=null
if(!q){e0=d8.a
c7=e0.c
c7===$&&A.b()
e0=e0.b
e0===$&&A.b()
c7.c5(e0)}e0=d8.a.c
e0===$&&A.b()
e0=e0.ga5()
c8=e0==null?d9:e0.a
p=c8==null?0:c8
o=0
try{n=d8.r.I(s,new A.k2(d8,r))
e0=d8.a.c
e0===$&&A.b()
c7=n
m=e0.a_(c7.c+"/"+c7.b+".db")
l=m.a4()
k=A.a([],t.J)
c9=e1.b
j=c9
i=!1
if(j instanceof A.a1&&j.b==="="&&j.c instanceof A.H){h=t.w.a(j.c)
if(h.b.length===1||B.b.gH(h.b).toLowerCase()===s){g=B.b.gW(h.b).toLowerCase()
e0=d8.a.b
e0===$&&A.b()
f=e0.b5(s,g)
if(f!=null){e=d8.f.I(j.d,new A.k3(j))
d=e.$1(A.o(t.N,t.r))
if(d instanceof A.p)d0=d.a
else d0=d instanceof A.j?d.a:d9
c=d0
if(c!=null){b=d8.a.b6(f.a.toLowerCase())
a=b.bj(A.a([c],t.n))
if(a!=null){e0=d8.a.c
e0===$&&A.b()
c7=n
a0=e0.C(c7.c+"/"+c7.b+".db",a.a)
a1=A.ab(a0,a.b)
if(a1!=null){a2=null
try{a3=A.aW(a1)
e0=d8.a.c
e0===$&&A.b()
a4=e0.ga5()
e0=d8.a.c
e0===$&&A.b()
a5=e0.ax
e0=a4
d1=e0==null?d9:e0.b
a6=d1==null?B.u:d1
if(a5.aC(a3.a,a3.b,p,a6))a2=A.a0(a3.d,d9,d9)}catch(d2){a2=A.a0(a1,d9,d9)}if(a2!=null)J.ae(k,new A.cs(a.a,a.b,a2))}e0=d8.a.c
e0===$&&A.b()
c7=n
e0.u(c7.c+"/"+c7.b+".db",a.a,!1)}i=!0}}}}if(!i)for(a7=0,e0=c9!=null,c7=d8.CW,d3=d8.f;a7<l;++a7){d4=d8.a.c
d4===$&&A.b()
d5=n
a8=d4.C(d5.c+"/"+d5.b+".db",a7)
a9=A.aT(a8)
for(b0=0;b0<a9;++b0){b1=A.ab(a8,b0)
if(b1!=null){b2=null
try{b3=A.aW(b1)
d4=d8.a.c
d4===$&&A.b()
b4=d4.ga5()
d4=d8.a.c
d4===$&&A.b()
b5=d4.ax
d4=b4
a6=d4==null?d9:d4.b
b6=a6==null?B.u:a6
if(b5.aC(b3.a,b3.b,p,b6))b2=A.a0(b3.d,d9,d9)}catch(d2){b2=A.a0(b1,d9,d9)}if(b2!=null){b7=!0
if(e0){b8=c7.I(r.a.toLowerCase(),new A.k4(r))
b9=new A.aN(b2,b8)
c0=d3.I(c9,new A.k5(e1))
c1=c0.$1(b9)
if(!(c1 instanceof A.p&&c1.a===1))d6=c1 instanceof A.j&&c1.a>0
else d6=!0
b7=d6}if(b7)J.ae(k,new A.cs(a7,b0,b2))}}}d4=d8.a.c
d4===$&&A.b()
d5=n
d4.u(d5.c+"/"+d5.b+".db",a7,!1)}c2=d8.hO(r.a)
e0=d8.a.b
e0===$&&A.b()
c3=e0.bg(r.a)
c4=A.aD(t.N)
for(e0=k,c7=e0.length,d7=0;d7<e0.length;e0.length===c7||(0,A.n)(e0),++d7){c5=e0[d7]
n.cn(c5.a,c5.b,p);++o
d3=c3.a>0?c3.a-1:0
c3.a=d3
if(c2)for(c6=0;c6<r.b.length;++c6)d8.e_(r.a,r.b[c6],c5.c[c6],p,c4)}if(!q){e0=d8.a.c
e0===$&&A.b()
e0.cl()}d8.a.cB(s)
e0=A.a([],t.s)
c7=A.a([],t.F)
d3=A.D(o)
return new A.B(e0,c7,d3+" rows deleted successfully.",B.f)}catch(d2){if(!q){e0=d8.a
c7=e0.c
c7===$&&A.b()
e0=e0.b
e0===$&&A.b()
c7.bE(e0)}throw d2}},
hB(h2){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2,b3,b4,b5,b6,b7,b8,b9,c0,c1,c2,c3,c4,c5,c6,c7,c8,c9,d0,d1,d2,d3,d4,d5,d6,d7,d8,d9,e0,e1,e2,e3,e4,e5,e6,e7,e8,e9,f0,f1,f2,f3,f4,f5,f6,f7,f8,f9,g0,g1,g2,g3,g4,g5,g6,g7,g8,g9=this,h0=null,h1=g9.a.b
h1===$&&A.b()
f0=h2.a
if(!h1.c0(g9.b,f0,"update"))throw A.c(A.q("Permission denied: UPDATE privilege required on table '"+f0+"' for user '"+g9.b+"'."))
g9.aU()
s=f0.toLowerCase()
h1=g9.a.b
h1===$&&A.b()
r=h1.c.h(0,s.toLowerCase())
if(r==null)throw A.c(A.q("Table '"+A.D(s)+"' does not exist."))
if(r.d)throw A.c(A.q("Updates are not supported on columnar tables."))
q=B.b.c1(r.b,new A.kC(h2))
if(J.az(q,-1))throw A.c(A.q("Column '"+h2.b+"' does not exist on table '"+A.D(s)+"'."))
h1=g9.a.c
h1===$&&A.b()
p=h1.gab()!=null
if(!p){h1=g9.a
f0=h1.c
f0===$&&A.b()
h1=h1.b
h1===$&&A.b()
f0.c5(h1)}h1=g9.a.c
h1===$&&A.b()
h1=h1.ga5()
f1=h1==null?h0:h1.a
o=f1==null?0:f1
n=0
try{m=g9.r.I(s,new A.kD(g9,r))
l=A.a([],t.J)
h1=g9.a.c
h1===$&&A.b()
f0=m
k=h1.a_(f0.c+"/"+f0.b+".db")
j=k.a4()
f2=h2.d
i=f2
h=null
if(i!=null){h1=g9.a.d
h1===$&&A.b()
h=h1.j0(s,i)}if(h!=null){g=g9.a.b6(h.a.a.toLowerCase())
f=g.cP(h.b,h.c)
J.pI(f,new A.kE())
for(h1=f,f0=h1.length,f3=0;f3<h1.length;h1.length===f0||(0,A.n)(h1),++f3){e=h1[f3]
f4=g9.a.c
f4===$&&A.b()
f5=m
d=f4.C(f5.c+"/"+f5.b+".db",e.a)
c=A.ab(d,e.b)
if(c!=null){b=null
try{a=A.aW(c)
f4=g9.a.c
f4===$&&A.b()
a0=f4.ga5()
f4=g9.a.c
f4===$&&A.b()
a1=f4.ax
f4=a0
b2=f4==null?h0:f4.b
a2=b2==null?B.u:b2
if(a1.aC(a.a,a.b,o,a2))b=A.a0(a.d,h0,h0)}catch(f6){b=A.a0(c,h0,h0)}if(b!=null)J.ae(l,new A.cs(e.a,e.b,b))}f4=g9.a.c
f4===$&&A.b()
f5=m
f4.u(f5.c+"/"+f5.b+".db",e.a,!1)}}else for(a3=0,h1=f2!=null,f0=g9.CW,f4=g9.f;a3<j;++a3){f5=g9.a.c
f5===$&&A.b()
f7=m
a4=f5.C(f7.c+"/"+f7.b+".db",a3)
a5=A.aT(a4)
for(a6=0;a6<a5;++a6){a7=A.ab(a4,a6)
if(a7!=null){a8=null
try{a9=A.aW(a7)
f5=g9.a.c
f5===$&&A.b()
b0=f5.ga5()
f5=g9.a.c
f5===$&&A.b()
b1=f5.ax
f5=b0
a2=f5==null?h0:f5.b
b2=a2==null?B.u:a2
if(b1.aC(a9.a,a9.b,o,b2))a8=A.a0(a9.d,h0,h0)}catch(f6){a8=A.a0(a7,h0,h0)}if(a8!=null){b3=!0
if(h1){b4=f0.I(r.a.toLowerCase(),new A.kF(r))
b5=new A.aN(a8,b4)
b6=f4.I(f2,new A.kG(h2))
b7=b6.$1(b5)
if(!(b7 instanceof A.p&&b7.a===1))f8=b7 instanceof A.j&&b7.a>0
else f8=!0
b3=f8}if(b3)J.ae(l,new A.cs(a3,a6,a8))}}}f5=g9.a.c
f5===$&&A.b()
f7=m
f5.u(f7.c+"/"+f7.b+".db",a3,!1)}b8=g9.f.I(h2.c,new A.kH(h2))
b9=g9.CW.I(r.a.toLowerCase(),new A.kI(r))
for(h1=l,f0=h1.length,f4=t.n,f5=g9.z,f7=t.s,f9=t.e,g0=f9.i("u.E"),g1=g9.e,g2=t.r,f3=0;f3<h1.length;h1.length===f0||(0,A.n)(h1),++f3){c0=h1[f3]
c1=new A.aN(c0.c,b9)
c2=b8.$1(c1)
c3=r.c[q]
c4=c2
if(!(c4 instanceof A.d)&&c4.gae()!==c3)if(c3===B.L&&c4 instanceof A.p)c4=new A.j(c4.a)
else if(c3===B.M&&c4 instanceof A.m)try{c4=new A.M(B.o.ag(c4.a),h0)}catch(f6){}c5=A.a6(c0.c,!0,g2)
J.aY(c5,q,c4)
g3=g9.a.b
g3===$&&A.b()
c6=g3.cL(s,"BEFORE","UPDATE")
for(g3=c6,g4=g3.length,g5=0;g5<g3.length;g3.length===g4||(0,A.n)(g3),++g5){c7=g3[g5]
g9.d2(c7,r,c5)}c8=A.p1(c5)
c9=new A.ci(o,0,0,c8)
d0=c9.al()
g3=g9.a.c
g3===$&&A.b()
g4=m
d1=g3.C(g4.c+"/"+g4.b+".db",c0.a)
g4=d1.c
g4===$&&A.b()
d2=g4
d3=5+c0.b*4
d4=J.is(d2,d3,!1)
d5=J.is(d2,d3+2,!1)
if(J.O(d0)<=d5){B.j.aj(d1.b,d4,d0)
g3=d2
g4=J.O(d0)
g3.$flags&2&&A.i(g3,10)
J.it(g3,d3+2,g4,!1)
g4=g9.a.c
g4===$&&A.b()
g3=m
g4.u(g3.c+"/"+g3.b+".db",c0.a,!0);++n}else{d6=J.is(d2,3,!1)
d7=J.is(d2,1,!1)
d8=5+d7*4
if(d6-d8>=J.O(d0)){d9=d6-J.O(d0)
B.j.aj(d1.b,d9,d0)
g3=d2
g3.$flags&2&&A.i(g3,10)
J.it(g3,d3,d9,!1)
g3=d2
g4=J.O(d0)
g3.$flags&2&&A.i(g3,10)
J.it(g3,d3+2,g4,!1)
g4=d2
g4.$flags&2&&A.i(g4,10)
J.it(g4,3,d9,!1)
g4=g9.a.c
g4===$&&A.b()
g3=m
g4.u(g3.c+"/"+g3.b+".db",c0.a,!0);++n}else{g3=g9.a.c
g3===$&&A.b()
g4=m
g3.u(g4.c+"/"+g4.b+".db",c0.a,!1)
m.cn(c0.a,c0.b,o)
e0=m.dC(c5,o)
g4=g9.a.b
g4===$&&A.b()
e1=g4.bf(s)
for(g3=J.as(e1);g3.p();){e2=g3.gD()
e3=f5.I(e2,new A.kJ(e2))
g6=A.r(new A.h(A.a(e2.c.split(","),f7),new A.kK(),f9),g0)
e4=g6
e5=A.a([],f4)
for(g4=e4,g7=g4.length,g5=0;g5<g4.length;g4.length===g7||(0,A.n)(g4),++g5){e6=g4[g5]
e7=B.b.c1(r.b,new A.kL(e6))
if(!J.az(e7,-1)){e8=J.Y(c5,e7)
if(e8 instanceof A.p)g8=e8.a
else g8=e8 instanceof A.j?e8.a:0
e9=g8
J.ae(e5,e9)}}if(J.O(e5)!==0)g1.push(new A.bk(e3,s,e2.c,e5,e0.a,e0.b))}++n}}}if(!p){h1=g9.a.c
h1===$&&A.b()
h1.cl()}g9.a.cB(s)
h1=A.a([],f7)
f0=A.a([],t.F)
f4=A.D(n)
return new A.B(h1,f0,f4+" rows updated successfully.",B.f)}catch(f6){if(!p){h1=g9.a
f0=h1.c
f0===$&&A.b()
h1=h1.b
h1===$&&A.b()
f0.bE(h1)}throw f6}},
e_(a,b,c,d,e){var s,r,q,p,o,n,m,l
if(e.E(0,a.toLowerCase()))return
e.T(0,a.toLowerCase())
s=this.a.b
s===$&&A.b()
s=s.c
s=new A.ao(s,s.r,s.e,A.E(s).i("ao<2>"))
while(s.p()){r=s.d
for(q=r.b,p=r.r,o=r.w,r=r.a,n=0;n<q.length;++n){m=p[n]
l=o[n]
if(m!=null&&l!=null)if(m.toLowerCase()===a.toLowerCase()&&l.toLowerCase()===b.toLowerCase())this.h9(r,q[n],c,d,e)}}e.S(0,a.toLowerCase())},
h9(a8,a9,b0,b1,b2){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5=this,a6=null,a7=a5.a.b
a7===$&&A.b()
m=a7.c.h(0,a8.toLowerCase().toLowerCase())
if(m==null)return
l=a5.r.I(a8.toLowerCase(),new A.jK(a5,m))
a7=a5.a.c
a7===$&&A.b()
k=l.c+"/"+l.b+".db"
j=a7.a_(k).a4()
a7=m.dx
a7===$&&A.b()
i=B.b.ac(a7,a9.toLowerCase())
if(i===-1)return
h=A.a([],t.J)
for(g=0;g<j;++g){a7=a5.a.c
a7===$&&A.b()
f=a7.C(k,g)
e=A.aT(f)
for(d=0;d<e;++d){s=A.ab(f,d)
if(s!=null){r=null
try{q=A.aW(s)
a7=a5.a.c
a7===$&&A.b()
p=a7.ga5()
a7=a5.a.c
a7===$&&A.b()
o=a7.ax
a7=p
c=a7==null?a6:a7.b
n=c==null?B.u:c
if(o.aC(q.a,q.b,b1,n))r=A.a0(q.d,a6,a6)}catch(b){r=A.a0(s,a6,a6)}if(r==null)continue
if(i<J.O(r))if(J.Y(r,i).A(0,b0)===0)h.push(new A.cs(g,d,r))}}a7=a5.a.c
a7===$&&A.b()
a7.u(k,g,!1)}for(a7=h.length,k=m.b,a=m.a,a0=0;a0<h.length;h.length===a7||(0,A.n)(h),++a0){a1=h[a0]
l.cn(a1.a,a1.b,b1)
a2=a5.a.b
a2===$&&A.b()
a3=a2.bg(a)
a2=a3.a
a3.a=a2>0?a2-1:0
for(a2=a1.c,a4=0;a4<k.length;++a4)a5.e_(a,k[a4],a2[a4],b1,b2)}},
ek(c9){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2,b3,b4,b5,b6,b7,b8,b9,c0,c1,c2,c3,c4,c5=this,c6=null,c7="Permission denied: SELECT privilege required on table '",c8=c5.a.b
c8===$&&A.b()
l=c9.b
if(!c8.c0(c5.b,l,"select"))throw A.c(A.q(c7+l+"' for user '"+c5.b+"'."))
c8=c9.f
if((c8.length!==0?B.b.gH(c8):c6)!=null){k=c5.a.b
k===$&&A.b()
j=c5.b
if(!k.c0(j,(c8.length!==0?B.b.gH(c8):c6).a,"select"))throw A.c(A.q(c7+c9.giQ(0).a+"' for user '"+c5.b+"'."))}c5.aU()
i=l.toLowerCase()
if(i==="information_schema.tables"||i==="information.tables"){h=A.a(["table_catalog","table_schema","table_name","table_type","is_columnar"],t.s)
g=A.a([],t.F)
c8=c5.a.b
c8===$&&A.b()
c8.c.a0(0,new A.ku(g))
return new A.B(h,g,""+g.length+" tables found.",B.f)}if(i==="information_schema.columns"||i==="information.columns"){h=A.a(["table_catalog","table_schema","table_name","column_name","ordinal_position","data_type","is_nullable"],t.s)
g=A.a([],t.F)
c8=c5.a.b
c8===$&&A.b()
c8.c.a0(0,new A.kv(g))
return new A.B(h,g,""+g.length+" columns found.",B.f)}if(i==="information_schema.schemata"||i==="information.schemata")return new A.B(A.a(["catalog_name","schema_name","schema_owner"],t.s),A.a([A.a([new A.m("ultsql"),new A.m("public"),new A.m(c5.b)],t.K)],t.F),"1 schema found.",B.f)
l=c9.d
k=l==null
if((k?c6:l.b.toLowerCase())==="generate_series"||i==="generate_series"){f=k?c6:l.c
if(f==null)f=A.a([],t.U)
if(f.length!==0){e=A.K(f[0]).$1(A.o(t.N,t.r))
if(e instanceof A.p)d=e.a
else{d=A.a4(e.l(0),c6)
if(d==null)d=1}}else d=1
if(f.length>1){c=A.K(f[1]).$1(A.o(t.N,t.r))
if(c instanceof A.p)b=c.a
else{b=A.a4(c.l(0),c6)
if(b==null)b=10}}else b=10
if(f.length>2){a=A.K(f[2]).$1(A.o(t.N,t.r))
if(a instanceof A.p)a0=a.a
else{a0=A.a4(a.l(0),c6)
if(a0==null)a0=1}}else a0=1
g=A.a([],t.F)
if(a0>0)for(c8=t.K,a1=d;a1<=b;a1+=a0)g.push(A.a([A.v(a1)],c8))
else if(a0<0)for(c8=t.K,a1=d;a1>=b;a1+=a0)g.push(A.a([A.v(a1)],c8))
a2=c9.e
return new A.B(A.a([a2==null?"generate_series":a2],t.s),g,""+g.length+" rows generated.",B.f)}l=c5.a.b
l===$&&A.b()
a3=l.c.h(0,i.toLowerCase())
l=!1
if(a3!=null)if(!a3.d)if(c9.r!=null)c8=(c8.length!==0?B.b.gH(c8):c6)==null&&c9.as==null&&c9.w==null&&!A.v2(c9.a)
else c8=l
else c8=l
else c8=l
if(c8){a4=c9.r
if(a4 instanceof A.a1&&a4.b==="="&&a4.c instanceof A.H){c8=t.w.a(a4.c).b
if(c8.length===1||B.b.gH(c8).toLowerCase()===i){c8=B.b.gW(c8)
l=c5.a.b
l===$&&A.b()
a5=l.b5(i,c8.toLowerCase())
if(a5!=null){c8=a4.d
if(c8 instanceof A.ag){a6=c8.b
a7=typeof a6=="number"?a6:c6
if(a7!=null){c8=a5.a
a8=c5.a.b6(c8.toLowerCase()).bj(A.a([a7],t.n))
if(a8!=null){c8=c5.a
l=c8.c
l===$&&A.b()
k=a3.a
a9=A.aO(l,c8.a,k)
c8=c5.a.c
c8===$&&A.b()
l=a9.c+"/"+a9.b+".db"
j=a8.a
s=A.ab(c8.C(l,j),a8.b)
g=A.a([],t.F)
if(s!=null){r=null
try{q=A.aW(s)
c8=c5.a.c
c8===$&&A.b()
p=c8.ga5()
c8=c5.a.c
c8===$&&A.b()
o=c8.ax
c8=p
b0=c8==null?c6:c8.a
n=b0==null?0:b0
c8=p
b1=c8==null?c6:c8.b
m=b1==null?B.u:b1
if(o.aC(q.a,q.b,n,m))r=A.a0(q.d,c6,c6)}catch(b2){r=A.a0(s,c6,c6)}if(r!=null){b3=A.o(t.N,t.r)
for(c8=a3.b,k+=".",a1=0;a1<c8.length;++a1){b3.k(0,k+c8[a1],J.Y(r,a1))
b3.k(0,c8[a1],J.Y(r,a1))}b4=A.a([],t.K)
b5=A.a([],t.s)
b6=c9.a
if(b6.length===1){k=b6[0].a
k=k instanceof A.H&&B.b.gH(k.b)==="*"}else k=!1
if(k){k=A.z(c8).i("h<1,ai>")
b6=A.r(new A.h(c8,new A.kw(),k),k.i("u.E"))}for(c8=b6.length,b7=0;b7<b6.length;b6.length===c8||(0,A.n)(b6),++b7){b8=b6[b7]
k=b8.a
b9=A.bM(k,b3)
b4.push(b9)
c0=b8.b
if(c0==null)k=k instanceof A.H?B.b.R(k.b,"."):b9.l(0)
else k=c0
b5.push(k)}g.push(b4)
c8=c5.a.c
c8===$&&A.b()
c8.u(l,j,!1)
c5.cU(c9,b5,g)
return new A.B(b5,g,"Index scan completed successfully.",B.f)}}c8=c5.a.c
c8===$&&A.b()
c8.u(l,j,!1)}}}}}}}c8=c5.a.d
c8===$&&A.b()
c1=c8.aM(c9)
if(new A.kz().$1(c1))return new A.kx(c5,c1,c9).$0()
else{c1.N()
g=A.a([],t.F)
b5=A.a([],t.s)
for(c8=t.K,c2=!1;;){c3=c1.K()
if(c3==null)break
if(!c2){b5=c3.gZ().aO(0)
c2=!0}c4=A.a([],c8)
for(l=b5.length,b7=0;b7<b5.length;b5.length===l||(0,A.n)(b5),++b7){k=c3.h(0,b5[b7])
c4.push(k==null?new A.d():k)}g.push(c4)}c1.L()
c5.cU(c9,b5,g)
return new A.B(b5,g,""+g.length+" rows returned.",B.f)}},
hA(a){var s,r,q,p,o,n,m,l,k,j
this.aU()
s=this.a.d
s===$&&A.b()
r=s.is(a)
r.N()
q=A.a([],t.F)
p=A.a([],t.s)
for(s=t.K,o=!1;;){n=r.K()
if(n==null)break
if(!o){p=n.gZ().aO(0)
o=!0}m=A.a([],s)
for(l=p.length,k=0;k<p.length;p.length===l||(0,A.n)(p),++k){j=n.h(0,p[k])
m.push(j==null?new A.d():j)}q.push(m)}r.L()
return new A.B(p,q,""+q.length+" rows returned.",B.f)},
hf(a){var s=this.c,r=a.a
if(!s.F(r))throw A.c(A.q("Variable '"+r+"' is not declared."))
s.k(0,r,this.f.I(a.b,new A.jM(a)).$1(s))},
hm(a){this.d.push(this.f.I(a.a,new A.k1(a)).$1(this.c).l(0))},
hy(){var s=A.a(["table_name","columns","type"],t.s),r=A.a([],t.F),q=this.a.b
q===$&&A.b()
q.c.a0(0,new A.kA(r))
return new A.B(s,r,""+r.length+" tables found.",B.f)},
hx(a){var s,r,q=A.a(["index_name","table_name","column_name","type"],t.s),p=A.a([],t.F),o=a.a,n=this.a.b
if(o!=null){n===$&&A.b()
s=n.bf(o)}else{n===$&&A.b()
o=n.e
n=A.E(o).i("b1<2>")
s=A.r(new A.b1(o,n),n.i("F.E"))}for(o=J.as(s),n=t.K;o.p();){r=o.gD()
p.push(A.a([new A.m(r.a),new A.m(r.b),new A.m(r.c),new A.m("B+ Tree")],n))}return new A.B(q,p,""+p.length+" indexes found.",B.f)},
d1(a){return this.hj(a)},
hj(h1){var s=0,r=A.b6(t.V),q,p=this,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2,b3,b4,b5,b6,b7,b8,b9,c0,c1,c2,c3,c4,c5,c6,c7,c8,c9,d0,d1,d2,d3,d4,d5,d6,d7,d8,d9,e0,e1,e2,e3,e4,e5,e6,e7,e8,e9,f0,f1,f2,f3,f4,f5,f6,f7,f8,f9,g0,g1,g2,g3,g4,g5,g6,g7,g8,g9,h0
var $async$d1=A.b7(function(h3,h4){if(h3===1)return A.b3(h4,r)
for(;;)switch(s){case 0:g4=h1.a
g5=g4.toLowerCase()
g6=h1.b
g7=g6.toLowerCase()
g8=h1.c
g9=g8.toLowerCase()
h0=p.a.b
h0===$&&A.b()
if(h0.e.F(g5.toLowerCase()))throw A.c(A.q("Index '"+g5+"' already exists."))
h0=p.a.b
h0===$&&A.b()
l=h0.c.h(0,g7.toLowerCase())
if(l==null)throw A.c(A.q("Table '"+g7+"' does not exist."))
k=g9.split(",")
j=A.a([],t.t)
for(h0=k.length,i=0;i<h0;++i){h=B.a.V(k[i])
g=l.dx
g===$&&A.b()
f=B.b.ac(g,h)
g=f===-1
if(g&&!B.a.E(h,"->")&&!B.a.E(h,"("))throw A.c(A.q("Column '"+h+"' does not exist in table '"+g7+"'."))
if(!g)j.push(f)}h0=h1.d
if(h0==null)e=null
else{g=A.T(h0,"_","").toLowerCase()
e=g}if(e==null)e=""
d=e==="hnsw"||e==="ivf"||e==="ivfflat"
g=l.d
if(g&&!d)throw A.c(A.q("B+ Tree indexes are not supported on columnar tables."))
c=p.a.b
c===$&&A.b()
c.f5(new A.b9(g4,g6,g8,h0),!0)
if(e==="ivf"||e==="ivfflat"){g4=p.a
g6=g4.a+"/"
b=A.q0(!1,g6+g5+".ivf_flat","euclidean")
a=j.length!==0?j[0]:0
if(g){g4=g4.c
g4===$&&A.b()
a0=g6+l.a+".col_"+a
a1=g4.a_(a0).a4()
for(a2=0;a2<a1;++a2){g4=p.a.c
g4===$&&A.b()
a3=g4.C(a0,a2)
g4=a3.c
g4===$&&A.b()
a4=g4.getUint16(1,!1)
for(a5=0;a5<a4;++a5){o=A.ab(a3,a5)
if(o!=null){a6=A.bT(A.at(o,0,null),0,o.length)
if(a6 instanceof A.a5)b.b4(a6,a2,a5)}}g4=p.a.c
g4===$&&A.b()
g4.u(a0,a2,!1)}}b.bh()
q=new A.B(A.a([],t.s),A.a([],t.F),"IVF-FLAT Vector Index '"+g5+"' created successfully.",B.f)
s=1
break}if(h0==="hnsw"){a7=A.oN(!1,p.a.a+"/"+g5+".hnsw","euclidean")
a=j[0]
g4=p.a
g6=l.a
g8=g4.c
g4=g4.a
if(g){g8===$&&A.b()
a0=g4+"/"+g6+".col_"+a
a1=g8.a_(a0).a4()
for(a2=0;a2<a1;++a2){g4=p.a.c
g4===$&&A.b()
a3=g4.C(a0,a2)
g4=a3.c
g4===$&&A.b()
a4=g4.getUint16(1,!1)
for(a5=0;a5<a4;++a5){a8=5+a5*4
a9=g4.getUint16(a8,!1)
if(g4.getUint16(a8+2,!1)===0||a9>=4096)continue
o=A.ab(a3,a5)
if(o!=null){a6=A.bT(A.at(o,0,null),0,o.length)
if(a6 instanceof A.a5)a7.b4(a6,a2,a5)}}g4=p.a.c
g4===$&&A.b()
g4.u(a0,a2,!1)}}else{g8===$&&A.b()
b0=A.aO(g8,g4,g6)
g4=p.a.c
g4===$&&A.b()
g6=b0.c+"/"+b0.b+".db"
a1=g4.a_(g6).a4()
for(a2=0;a2<a1;++a2){g4=p.a.c
g4===$&&A.b()
a3=g4.C(g6,a2)
g4=a3.c
g4===$&&A.b()
a4=g4.getUint16(1,!1)
for(a5=0;a5<a4;++a5){a8=5+a5*4
a9=g4.getUint16(a8,!1)
if(g4.getUint16(a8+2,!1)===0||a9>=4096)continue
o=A.ab(a3,a5)
if(o!=null){b1=A.a0(o,null,null)
if(a<b1.length){a6=b1[a]
if(a6 instanceof A.a5)a7.b4(a6,a2,a5)}}}g4=p.a.c
g4===$&&A.b()
g4.u(g6,a2,!1)}}a7.bh()
q=new A.B(A.a([],t.s),A.a([],t.F),"HNSW Vector Index '"+g5+"' created successfully.",B.f)
s=1
break}g6=p.a
g8=g6.c
g8===$&&A.b()
b2=A.fU(g8,g6.a+"/"+g5+".idx",k.length)
b2.av()
g6=p.a
g8=g6.c
g8===$&&A.b()
b0=A.aO(g8,g6.a,l.a)
g6=p.a.c
g6===$&&A.b()
g8=b0.c+"/"+b0.b+".db"
a1=g6.a_(g8).a4()
b3=k.length
g6=p.a.b
g6===$&&A.b()
b4=g6.bg(g7)
b5=b4.a
if(b5<=0&&a1>0)b5=a1*100
b6=new Float64Array(b5*b3)
b7=new Int32Array(b5)
b8=new Int32Array(b5)
g6=l.b
b9=g6.length
h0=b3===1
c0=0
if(h0)if(j.length===0)for(g=t.N,c=t.r,c1=t.s,a2=0;a2<a1;++a2){c2=p.a.c
c2===$&&A.b()
a3=c2.C(g8,a2)
a4=A.aT(a3)
for(a5=0;a5<a4;++a5){o=A.ab(a3,a5)
if(o!=null){n=null
try{m=A.aW(o)
n=A.a0(m.d,null,null)}catch(h2){n=A.a0(o,null,null)}if(J.O(n)!==0){c4=A.o(g,c)
for(c5=0;c5<g6.length;++c5)c4.k(0,g6[c5],J.Y(n,c5))
c6=g9.split("->>")
if(c6.length===2){c2=c6[0]
c7=B.a.V(A.T(c2,"(",""))
c2=c6[1]
c2=A.T(c2,"'","")
c2=A.T(c2,'"',"")
c2=A.T(c2,")","")
c8=B.a.V(A.T(c2,"(",""))
c9=c4.h(0,c7)
if(c9 instanceof A.M){d0=c9.aY(A.a([c8],c1))
if(d0 instanceof A.p)d1=d0.a
else if(d0 instanceof A.j)d1=d0.a
else if(d0 instanceof A.m){d2=d0.a
d3=A.aH(d2)
if(d3!=null)d1=d3
else{for(c2=d2.length,d4=0,d5=0;d5<c2;++d5)d4=B.c.a7(d4*31+d2.charCodeAt(d5),9007199254740991)
d1=d4}}else d1=null
if(d1!=null){c2=b6.length
if(c0>=c2){d6=c2*2+100
d7=new Float64Array(d6)
d8=new Int32Array(d6)
d9=new Int32Array(d6)
B.ab.a8(d7,0,c2,b6)
B.E.a8(d8,0,b7.length,b7)
B.E.a8(d9,0,b8.length,b8)
b8=d9
b7=d8
b6=d7}b6.$flags&2&&A.i(b6)
b6[c0]=d1
b7.$flags&2&&A.i(b7)
b7[c0]=a2
b8.$flags&2&&A.i(b8)
b8[c0]=a5;++c0}}}}}}c2=p.a.c
c2===$&&A.b()
c2.u(g8,a2,!1)}else{e0=j[0]
for(g6=e0+1,g=e0*2,c=g6*2,a2=0;a2<a1;++a2){c1=p.a.c
c1===$&&A.b()
c1=c1.C(g8,a2).c
c1===$&&A.b()
a4=c1.getUint16(1,!1)
for(a5=0;a5<a4;++a5){a8=5+a5*4
a9=c1.getUint16(a8,!1)
e1=c1.getUint16(a8+2,!1)
if(e1===0||a9>=4096)continue
if(e1>=12){e2=a9+12
if(c1.getUint16(e2,!1)===b9)e3=e1-12
else{e3=e1
e2=a9}}else{e3=e1
e2=a9}e4=c1.getUint16(e2,!1)
if(e0>=e4)continue
c2=e2+2
e5=c1.getUint16(c2+g,!1)
e6=(g6<e4?c1.getUint16(c2+c,!1):e3)-e5
if(e6<=0)continue
e7=e2+e5
e8=c1.getUint8(e7)
if(e8===1){e9=e6-1
if(e9===1)d1=c1.getInt8(e7+1)
else if(e9===2)d1=c1.getInt16(e7+1,!1)
else if(e9===4)d1=c1.getInt32(e7+1,!1)
else d1=e9===8?B.r.c2(c1,e7+1).j9(0):null}else if(e8===2)d1=c1.getFloat64(e7+1,!1)
else if(e8===3){f0=J.bm(B.r.gai(c1),c1.byteOffset+(e7+1),e6-1)
d2=new A.cZ(!1).bJ(f0,0,null,!0)
d3=A.aH(d2)
if(d3!=null)d1=d3
else{for(c2=d2.length,d4=0,d5=0;d5<c2;++d5)d4=B.c.a7(d4*31+d2.charCodeAt(d5),9007199254740991)
d1=d4}}else d1=null
if(d1!=null){if(c0>=b5){f1=B.h.bd(b5*1.5)+100
d7=new Float64Array(f1)
B.ab.a8(d7,0,c0,b6)
d8=new Int32Array(f1)
B.E.a8(d8,0,c0,b7)
d9=new Int32Array(f1)
B.E.a8(d9,0,c0,b8)
b8=d9
b7=d8
b6=d7
b5=f1}b6.$flags&2&&A.i(b6)
b6[c0]=d1
b7.$flags&2&&A.i(b7)
b7[c0]=a2
b8.$flags&2&&A.i(b8)
b8[c0]=a5;++c0}}c1=p.a.c
c1===$&&A.b()
c1.u(g8,a2,!1)}}else{f2=A.a9(b3,0,!1,t.i)
for(a2=0;a2<a1;++a2){g6=p.a.c
g6===$&&A.b()
g6=g6.C(g8,a2).c
g6===$&&A.b()
a4=g6.getUint16(1,!1)
for(a5=0;a5<a4;++a5){a8=5+a5*4
a9=g6.getUint16(a8,!1)
e1=g6.getUint16(a8+2,!1)
if(e1===0||a9>=4096)continue
if(e1>=12){e2=a9+12
if(g6.getUint16(e2,!1)===b9)e3=e1-12
else{e3=e1
e2=a9}}else{e3=e1
e2=a9}e4=g6.getUint16(e2,!1)
g=e2+2
c5=0
for(;;){f3=!1
if(!(c5<b3)){f3=!0
break}f=j[c5]
if(f===-1||f>=e4)break
e5=g6.getUint16(g+f*2,!1)
c=f+1
e6=(c<e4?g6.getUint16(g+c*2,!1):e3)-e5
if(e6<=0)break
e7=e2+e5
e8=g6.getUint8(e7)
if(e8===1){e9=e6-1
if(e9===1)d1=g6.getInt8(e7+1)
else if(e9===2)d1=g6.getInt16(e7+1,!1)
else if(e9===4)d1=g6.getInt32(e7+1,!1)
else d1=e9===8?B.r.c2(g6,e7+1).j9(0):null}else if(e8===2)d1=g6.getFloat64(e7+1,!1)
else if(e8===3){f0=J.bm(B.r.gai(g6),g6.byteOffset+(e7+1),e6-1)
d2=new A.cZ(!1).bJ(f0,0,null,!0)
d3=A.aH(d2)
if(d3!=null)d1=d3
else{for(c=d2.length,d4=0,d5=0;d5<c;++d5)d4=B.c.a7(d4*31+d2.charCodeAt(d5),9007199254740991)
d1=d4}}else d1=null
if(d1==null)break
f2[c5]=d1;++c5}if(f3){if(c0>=b5){f1=B.h.bd(b5*1.5)+100
d7=new Float64Array(f1*b3)
B.ab.a8(d7,0,c0*b3,b6)
d8=new Int32Array(f1)
B.E.a8(d8,0,c0,b7)
d9=new Int32Array(f1)
B.E.a8(d9,0,c0,b8)
b8=d9
b7=d8
b6=d7
b5=f1}for(g=c0*b3,c=b6.$flags|0,c5=0;c5<b3;++c5){c1=f2[c5]
c&2&&A.i(b6)
b6[g+c5]=c1}b7.$flags&2&&A.i(b7)
b7[c0]=a2
b8.$flags&2&&A.i(b8)
b8[c0]=a5;++c0}}g6=p.a.c
g6===$&&A.b()
g6.u(g8,a2,!1)}}g6=c0===b5
if(g6)f4=b6
else f4=h0?A.pU(b6,0,c0):A.pU(b6,0,c0*b3)
f5=g6?b7:A.pX(b7,0,c0)
f6=g6?b8:A.pX(b8,0,c0)
f7=new Int32Array(c0)
for(c5=0;c5<c0;++c5)f7[c5]=c5
g6=c0-1
if(h0)A.pm(f7,f4,f5,f6,0,g6)
else A.pn(f7,f4,f5,f6,b3,0,g6)
b4.a=c0
b2.fm(f4,f5,f6,b3,f7)
f8=b4.b.I(g9,new A.jR())
g8=c0>0
if(g8){f9=1
if(h0){for(c5=1;c5<c0;++c5)if(f4[f7[c5]]!==f4[f7[c5-1]])++f9}else for(c5=1;c5<c0;++c5){h0=f7[c5]*b3
g=f7[c5-1]*b3
g1=0
for(;;){if(!(g1<b3)){g0=!1
break}if(f4[h0+g1]!==f4[g+g1]){g0=!0
break}++g1}if(g0)++f9}}else f9=0
f8.c+=f9
if(g8){g2=f4[f7[0]*b3]
g3=f4[f7[g6]*b3]
g6=f8.a
if(g6==null||g2<g6)f8.a=g2
g6=f8.b
if(g6==null||g3>g6)f8.b=g3}b4.a=c0
q=new A.B(A.a([],t.s),A.a([],t.F),"Index '"+g4+"' created successfully on '"+g7+"("+g9+")' ("+c0+" rows indexed).",B.f)
s=1
break
case 1:return A.b4(q,r)}})
return A.b5($async$d1,r)},
hu(a1){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0=this
for(j=a1.b,i=j.length,h=a0.cx,g=0;g<j.length;j.length===i||(0,A.n)(j),++g){f=j[g]
e=f.a
h.k(0,e.toLowerCase(),new A.i_(e,f.b))}for(j=a1.a,i=j.length,h=a0.c,e=a0.f,g=0;g<j.length;j.length===i||(0,A.n)(j),++g){d=j[g]
c=new A.d()
b=d.c
if(b!=null){c=e.I(b,new A.kr(d)).$1(h)
if(!(c instanceof A.d)&&c.gae()!==d.b){b=d.b
if(b===B.L&&c instanceof A.p)c=new A.j(c.a)
else throw A.c(A.q("Type mismatch in declaration of '"+d.a+"'. Expected "+b.l(0)+", found "+c.gae().l(0)+"."))}}h.k(0,d.a,c)}j=a0.a.c
j===$&&A.b()
s=j.gab()!=null
if(!s){j=a0.a
i=j.c
i===$&&A.b()
j=j.b
j===$&&A.b()
i.c5(j)}r=null
if(s){j=a1.d
j=j!=null&&j.length!==0}else j=!1
if(j){j=$.pY
$.pY=j+1
r="_auto_sp_"+j
j=a0.a
i=j.c
i===$&&A.b()
h=r
j=j.b
j===$&&A.b()
i.fe(h,j)}q=null
try{for(j=a1.c,i=j.length,g=0;g<j.length;j.length===i||(0,A.n)(j),++g){p=j[g]
o=a0.aA(p)
if(o instanceof A.ad){j=A.q("Asynchronous operations are not supported inside PL/SQL blocks.")
throw A.c(j)}if(o instanceof A.B)q=o}a0.aU()
a0.aQ()
if(!s){j=a0.a.c
j===$&&A.b()
j.cl()}}catch(a){n=A.aV(a)
B.b.v(a0.e)
a0.aQ()
if(!s){j=a0.a
i=j.c
i===$&&A.b()
j=j.b
j===$&&A.b()
i.bE(j)}else if(r!=null){j=a0.a
i=j.c
i===$&&A.b()
h=r
j=j.b
j===$&&A.b()
i.fs(h,j)}a0.r.v(0)
j=a1.d
if(j!=null&&j.length!==0){m=B.b.iE(j,new A.ks(n),new A.kt(a1))
for(j=m.b,i=j.length,g=0;g<j.length;j.length===i||(0,A.n)(j),++g){l=j[g]
k=a0.aA(l)
if(k instanceof A.ad)throw A.c(A.q("Asynchronous operations are not supported inside exception handlers."))
if(k instanceof A.B)q=k}}else throw a}j=q
return j==null?new A.B(A.a([],t.s),A.a([],t.F),"PL/SQL block executed successfully.",B.f):j},
ht(a){var s,r,q,p,o,n=this,m=n.f,l=n.c,k=m.I(a.a,new A.k8(a)).$1(l)
if(k instanceof A.p&&k.a===1){for(m=a.b,l=m.length,s=0;s<m.length;m.length===l||(0,A.n)(m),++s)if(n.aA(m[s]) instanceof A.ad)throw A.c(A.q("Asynchronous operations are not supported inside IF branches."))
return}for(r=a.c,q=r.length,s=0;s<r.length;r.length===q||(0,A.n)(r),++s){p=r[s]
o=m.I(p.a,new A.k9(p)).$1(l)
if(o instanceof A.p&&o.a===1){for(m=p.b,l=m.length,s=0;s<m.length;m.length===l||(0,A.n)(m),++s)if(n.aA(m[s]) instanceof A.ad)throw A.c(A.q("Asynchronous operations are not supported inside ELSIF branches."))
return}}m=a.d
if(m!=null)for(l=m.length,s=0;s<m.length;m.length===l||(0,A.n)(m),++s)if(n.aA(m[s]) instanceof A.ad)throw A.c(A.q("Asynchronous operations are not supported inside ELSE branches."))},
hD(a){var s,r,q,p,o,n=this.f.I(a.a,new A.kM(a))
for(s=a.b,r=this.c;;){q=n.$1(r)
if(q instanceof A.p&&q.a===1){for(p=s.length,o=0;o<s.length;s.length===p||(0,A.n)(s),++o)if(this.aA(s[o]) instanceof A.ad)throw A.c(A.q("Asynchronous operations are not supported inside WHILE loops."))}else break}},
aU(){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2,b3,b4,b5=this,b6=b5.e,b7=b6.length
if(b7===0)return
s=A.o(t.N,t.aQ)
for(r=0;r<b6.length;b6.length===b7||(0,A.n)(b6),++r){q=b6[r]
J.ae(s.I(q.a,new A.kN()),q)}for(b7=new A.an(s,s.$ti.i("an<1,2>")).gJ(0);b7.p();){p=b7.d
o=p.a
n=b5.a.b6(o)
m=p.b
k=J.X(m)
j=0
for(;;){if(!(j<k.gt(m)-1)){l=!0
break}i=k.h(m,j).d;++j
h=k.h(m,j).d
g=i.length
f=h.length
e=g<f?g:f
for(d=0,c=0;c<e;++c){d=B.h.A(i[c],h[c])
if(d!==0)break}if((d===0?B.c.A(g,f):d)>0){l=!1
break}}if(!l)k.aq(m,new A.kO())
if(k.gaa(m)&&k.h(m,0).d.length!==0){n.av()
b=n.iP(k.h(m,0).d[0])}else b=!1
if(b){a=b5.a.b
a===$&&A.b()
a0=a.bg(k.h(m,0).b).b.I(k.h(m,0).c,new A.kP())
a1=k.h(m,0).d.length
a=k.gt(m)
a2=new Float64Array(a*a1)
a=k.gt(m)
a3=new Int32Array(a)
a=k.gt(m)
a4=new Int32Array(a)
for(a5=0,a6=null,j=0;j<k.gt(m);++j){a7=k.h(m,j)
for(a=j*a1,a8=a7.d,a9=0;a9<a1;++a9)a2[a+a9]=a8[a9]
a3[j]=a7.e
a4[j]=a7.f
if(a6==null||!b5.h_(a6,a8)){++a5
a6=a8}}n.iJ(a2,a3,a4,a1)
a0.c+=a5
if(k.gaa(m)&&k.gH(m).d.length!==0){b0=k.gH(m).d[0]
b1=k.gW(m).d[0]
k=a0.a
if(k==null||b0<k)a0.a=b0
k=a0.b
if(k==null||b1>k)a0.b=b1}}else for(k=k.gJ(m);k.p();){a=k.gD()
b2=a.d
if(n.b4(b2,a.e,a.f)){b3=b5.a.b
b3===$&&A.b()
a0=b3.bg(a.b).b.I(a.c,new A.kQ());++a0.c
if(b2.length!==0){b4=b2[0]
a=a0.a
if(a==null||b4<a)a0.a=b4
a=a0.b
if(a==null||b4>a)a0.b=b4}}}}b5.aQ()
B.b.v(b6)},
aQ(){for(var s=this.r,s=new A.ao(s,s.r,s.e,A.E(s).i("ao<2>"));s.p();)s.d.bD()
s=this.a.c
s===$&&A.b()
s.iU()},
ce(){var s,r
for(s=this.r,s=new A.ao(s,s.r,s.e,A.E(s).i("ao<2>"));s.p();){r=s.d
if(r.r!=null){r.a.u(r.c+"/"+r.b+".db",r.w,!1)
r.r=null
r.w=-1}r.f=null}},
he(b6){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2=this,b3=null,b4=b6.a.toLowerCase(),b5=b2.a.b
b5===$&&A.b()
m=b5.c.h(0,b4.toLowerCase())
if(m==null)throw A.c(A.q("Table '"+b4+"' does not exist."))
if(m.d)throw A.c(A.q("Analyze is not supported on columnar tables."))
b5=b2.a.b
b5===$&&A.b()
l=b5.bg(m.a)
l.a=0
b5=l.b
b5.v(0)
k=b2.r.I(b4,new A.jL(b2,m))
j=b2.a.c
j===$&&A.b()
i=k.c+"/"+k.b+".db"
h=j.a_(i).a4()
g=A.o(t.S,t.eu)
for(j=m.b,f=t.r,e=0;e<j.length;++e)g.k(0,e,A.aD(f))
f=b2.a.c
f===$&&A.b()
d=f.ga5()
f=d==null
c=f?b3:d.a
s=c==null?0:c
b=f?b3:d.b
r=b==null?B.u:b
f=b2.a.c
f===$&&A.b()
q=f.ax
for(a=0;a<h;++a){f=b2.a.c
f===$&&A.b()
a0=f.C(i,a)
a1=A.aT(a0)
for(a2=0;a2<a1;++a2){p=A.ab(a0,a2)
if(p!=null){o=null
try{n=A.aW(p)
if(q.aC(n.a,n.b,s,r))o=A.a0(n.d,b3,b3)}catch(a3){o=A.a0(p,b3,b3)}if(o!=null){++l.a
for(e=0;e<j.length;++e)if(e<J.O(o)){a4=J.Y(o,e)
if(!(a4 instanceof A.d))g.h(0,e).T(0,a4)}}}}f=b2.a.c
f===$&&A.b()
f.u(i,a,!1)}for(e=0;e<j.length;++e){i=j[e]
a5=g.h(0,e)
f=a5.a
if(f!==0){a6=new A.bs(b3,b3,0)
a6.c=f
for(f=A.E(a5),a7=new A.c7(a5,a5.r,f.i("c7<1>")),a7.c=a5.e,f=f.c,a8=b3,a9=a8;a7.p();){b0=a7.d
b1=(b0==null?f.a(b0):b0).ga2()
if(typeof b1=="number"){if(a9==null||b1<a9)a9=b1
if(a8==null||b1>a8)a8=b1}}a6.a=a9
a6.b=a8
b5.k(0,i.toLowerCase(),a6)}}b5=b2.a.b
b5===$&&A.b()
b5.aE()
return new A.B(A.a(["status"],t.s),A.a([A.a([new A.m("SUCCESS")],t.K)],t.F),"Analyzed table '"+b4+"'. Row count: "+l.a+".",B.f)},
cU(a6,a7,a8){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4=this,a5=a4.b
if(a5==="admin"||a5==="system")return
a5=a7.length
s=A.a9(a5,null,!1,t.T)
r=a6.a
if(r.length===1){q=r[0].a
q=q instanceof A.H&&B.b.gH(q.b)==="*"}else q=!1
if(q){q=a4.a.b
q===$&&A.b()
p=q.c.h(0,a6.b.toLowerCase())
if(p!=null){q=p.as
o=p.b
n=0
for(;;){if(!(n<a7.length&&n<o.length))break
m=a7[n]
l=p.dx
l===$&&A.b()
k=B.b.ac(l,m.toLowerCase())
if(k!==-1)s[n]=q[k]
else s[n]=q[n];++n}}}else{q=a6.f
j=a6.b
n=0
for(;;){if(!(n<a7.length&&n<r.length))break
i=r[n].a
if(i instanceof A.H){o=i.b
l=o.length
h=null
if(l===1){g=B.b.gH(o)
o=a4.a.b
o===$&&A.b()
p=o.c.h(0,j.toLowerCase())
if(p!=null){o=p.dx
o===$&&A.b()
o=B.b.E(o,g.toLowerCase())}else o=!1
if(o)h=j
else{o=q.length
if(o!==0)for(f=0;f<q.length;q.length===o||(0,A.n)(q),++f){e=q[f]
l=a4.a.b
l===$&&A.b()
d=e.a
p=l.c.h(0,d.toLowerCase())
if(p!=null){l=p.dx
l===$&&A.b()
l=B.b.E(l,g.toLowerCase())}else l=!1
if(l){h=d
break}}}}else if(l>=2){h=o[l-2]
g=B.b.gW(o)}else g=""
if(h!=null){o=a4.a.b
o===$&&A.b()
p=o.c.h(0,h.toLowerCase())
if(p!=null){o=p.dx
o===$&&A.b()
k=B.b.ac(o,g.toLowerCase())
if(k!==-1)s[n]=p.as[k]}}}++n}}for(n=0;n<a5;++n){q=s[n]
c=q==null?null:q.toLowerCase()
if(c!=null)for(q=a8.length,o=c==="default",l=c==="email",b=c==="credit_card",f=0;f<a8.length;a8.length===q||(0,A.n)(a8),++f){a=a8[f]
a0=a[n]
if(a0 instanceof A.m){a1=a0.a
if(b){a2=a1.length
if(a2>=4)a[n]=new A.m("XXXX-XXXX-XXXX-"+B.a.az(a1,a2-4))
else a[n]=new A.m("XXXX")}else if(l){a3=a1.split("@")
if(a3.length===2&&a3[0].length!==0)a[n]=new A.m(a3[0][0]+"***@"+a3[1])
else a[n]=new A.m("***")}else if(o)a[n]=new A.m("XXXX")}}}},
hr(a){var s,r,q,p,o,n,m,l,k,j=this.f,i=j.I(a.b,new A.k6(a)),h=j.I(a.c,new A.k7(a))
j=this.c
s=i.$1(j)
r=h.$1(j)
q=s instanceof A.p?s.a:A.d4(s.l(0))
p=r instanceof A.p?r.a:A.d4(r.l(0))
for(o=a.d,n=a.a,m=q;m<=p;++m){j.k(0,n,A.v(m))
for(l=o.length,k=0;k<o.length;o.length===l||(0,A.n)(o),++k)this.aA(o[k])}return new A.B(A.a([],t.s),A.a([],t.F),"FOR loop executed.",B.f)},
hp(a){var s,r=this,q="' does not exist.",p=a.a,o=r.bI(p),n=r.a.b
n===$&&A.b()
if(!n.c.F(o.toLowerCase())){if(a.b)return new A.B(A.a([],t.s),A.a([],t.F),"Table '"+p+q,B.f)
throw A.c(A.q("Table '"+p+q))}r.aQ()
r.ce()
n=r.r
n.S(0,o)
n.S(0,p.toLowerCase())
n=r.a.b
n===$&&A.b()
n.c.S(0,o.toLowerCase())
n.aE()
n=r.a
s=n.c
s===$&&A.b()
s.iA(n.a+"/"+o+".db")
r.Q.v(0)
r.as.v(0)
$.ex.v(0)
r.f.v(0)
r.CW.v(0)
return new A.B(A.a([],t.s),A.a([],t.F),"Table '"+p+"' dropped successfully.",B.f)},
ho(a){return new A.B(A.a([],t.s),A.a([],t.F),"Index '"+a.a+"' dropped successfully.",B.f)},
bI(a){var s,r=B.a.V(a),q=r.length
if(q>=2)if(!(B.a.U(r,"'")&&B.a.B(r,"'")))s=B.a.U(r,'"')&&B.a.B(r,'"')
else s=!0
else s=!1
if(s)r=B.a.O(r,1,q-1)
return r.toLowerCase()},
ei(a){var s,r,q,p,o,n=a.a,m=this.bI(n),l=this.a.b
l===$&&A.b()
s=l.c.h(0,m.toLowerCase())
if(s==null)throw A.c(A.q("Table '"+n+"' does not exist."))
r=A.a(["column_name","data_type","nullable"],t.s)
q=A.a([],t.F)
for(n=s.b,l=s.c,p=t.K,o=0;o<n.length;++o)q.push(A.a([new A.m(n[o]),new A.m(l[o].b.toUpperCase()),new A.m("YES")],p))
return new A.B(r,q,""+q.length+" columns described.",B.f)},
hv(a){var s,r,q,p,o,n=a.a,m=this.bI(n),l=this.a.b
l===$&&A.b()
s=l.c.h(0,m.toLowerCase())
if(s==null)throw A.c(A.q("Table '"+n+"' does not exist."))
r=A.a(["cid","name","type","notnull","dflt_value","pk"],t.s)
q=A.a([],t.F)
for(n=s.b,l=s.c,p=t.K,o=0;o<n.length;++o)q.push(A.a([A.v(o),new A.m(n[o]),new A.m(l[o].b.toUpperCase()),A.v(0),new A.d(),A.v(0)],p))
return new A.B(r,q,""+q.length+" columns found.",B.f)},
hz(a){var s=this,r=a.a,q=s.bI(r),p=s.a.b
p===$&&A.b()
if(p.c.h(0,q.toLowerCase())==null)throw A.c(A.q("Table '"+q+"' does not exist."))
s.aQ()
s.ce()
p=s.r
p.S(0,q)
p.S(0,r.toLowerCase())
s.a.cB(q)
return new A.B(A.a([],t.s),A.a([],t.F),"Table '"+q+"' truncated successfully.",B.f)}}
A.kR.prototype={
$0(){var s,r,q,p,o,n=this.a.a.b
n===$&&A.b()
n=n.c
n=new A.ao(n,n.r,n.e,A.E(n).i("ao<2>"))
s=this.b
while(n.p())for(r=n.d.r,q=r.length,p=0;p<q;++p){o=r[p]
if(o!=null&&o.toLowerCase()===s)return!0}return!1},
$S:90}
A.kT.prototype={
$0(){var s=0,r=A.b6(t.V),q,p=2,o=[],n=this,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1
var $async$$0=A.b7(function(b2,b3){if(b2===1){o.push(b3)
s=p}for(;;)switch(s){case 0:a8=$.oL
a9=$.pS=n.b
if(!a8)B.b.v($.pT)
a8=new A.fc()
$.ou()
a8.cS()
$.oM=a8
$.oL=!0
a=new A.fc()
a.cS()
m=a
a8=n.a
a0=a8.d
B.b.v(a0)
a8.c.v(0)
l=!1
a1=a9.toLowerCase()
if(B.a.E(a1,"insert")||B.a.E(a1,"update")||B.a.E(a1,"delete")||B.a.E(a1,"create")||B.a.E(a1,"alter")||B.a.E(a1,"drop")){a2=a8.a.e
a2===$&&A.b()
a2.iW(a8.b,a9)}p=4
k=null
if($.ex.F(a9)){a9=$.ex.h(0,a9)
a9.toString
k=a9}else{j=new A.c_(a9)
i=j.bu()
a2=i
a3=A.z(a2).i("aJ<1>")
a4=A.r(new A.aJ(a2,new A.kS(),a3),a3.i("F.E"))
h=a4
if(J.O(h)!==0){a9=A.q("Lexer error: "+J.e3(h).b+" at Line "+J.e3(h).c+":"+J.e3(h).d)
throw A.c(a9)}g=new A.c1(i)
k=g.fp()
if(!B.a.E(a9.toLowerCase(),"set engine_option"))$.ex.k(0,a9,k)}if(J.O(k)===0){a9=A.q("No SQL statements found to execute.")
throw A.c(a9)}f=null
a9=t.s
e=A.a([],a9)
a2=k,a3=a2.length,a5=0
case 7:if(!(a5<a2.length)){s=9
break}d=a2[a5]
p=11
if(d instanceof A.dg||d instanceof A.df||d instanceof A.dd||d instanceof A.de||d instanceof A.cB||d instanceof A.cA||d instanceof A.bP)l=!0
c=a8.aA(d)
s=c instanceof A.ad?14:15
break
case 14:s=16
return A.ar(c,$async$$0)
case 16:c=b3
case 15:if(c instanceof A.B){f=c
if(c.c.length!==0)J.ae(e,c.c)}p=4
s=13
break
case 11:p=10
b0=o.pop()
B.b.v(a8.e)
a8.aQ()
a9=a8.a
a0=a9.c
a0===$&&A.b()
a9=a9.b
a9===$&&A.b()
a0.bE(a9)
throw b0
s=13
break
case 10:s=4
break
case 13:case 8:a2.length===a3||(0,A.n)(a2),++a5
s=7
break
case 9:a8.aU()
a8.aQ()
if(l){a2=a8.a.b
a2===$&&A.b()
a2.aE()
a8.ay.v(0)
a8.Q.v(0)
a8.as.v(0)
$.ex.v(0)
a8.f.v(0)
a8.CW.v(0)}a2=a8.a.c
a2===$&&A.b()
if(a2.gab()==null){a2=a8.a.c
a2===$&&A.b()
a2.bb()}a2=m
if(a2.b==null)a2.b=$.cN.$0()
a2=f
a2=a2==null?null:a2.b.length
A.tc(a2==null?0:a2)
b=J.oz(e,"\n")
if(f!=null){a9=f.a
a2=f.b
a3=J.O(b)===0?"Script executed successfully.":b
a7=A.iY(0,m.gbY())
A.a6(a0,!0,t.N)
q=new A.B(a9,a2,a3,a7)
s=1
break}a9=A.a([],a9)
a2=A.a([],t.F)
a3=J.O(b)===0?"Statement executed successfully.":b
a7=A.iY(0,m.gbY())
A.a6(a0,!0,t.N)
q=new A.B(a9,a2,a3,a7)
s=1
break
p=2
s=6
break
case 4:p=3
b1=o.pop()
a9=m
if(a9.b==null)a9.b=$.cN.$0()
B.b.v(a8.e)
a8.aQ()
a8=a8.a
a9=a8.c
a9===$&&A.b()
a8=a8.b
a8===$&&A.b()
a9.bE(a8)
throw b1
s=6
break
case 3:s=2
break
case 6:case 1:return A.b4(q,r)
case 2:return A.b3(o.at(-1),r)}})
return A.b5($async$$0,r)},
$S:40}
A.kS.prototype={
$1(a){return a.a===B.K},
$S:89}
A.kp.prototype={
$0(){return A.K(this.a.a)},
$S:0}
A.kq.prototype={
$1(a){var s=this.a
return s.f.I(a,new A.ko(a)).$1(s.c)},
$S:21}
A.ko.prototype={
$0(){return A.K(this.a)},
$S:0}
A.jO.prototype={
$1(a){var s=this.a
return s.f.I(a,new A.jN(a)).$1(s.c)},
$S:21}
A.jN.prototype={
$0(){return A.K(this.a)},
$S:0}
A.jT.prototype={
$1(a){return a.b===B.W},
$S:13}
A.jU.prototype={
$1(a){return a.a},
$S:45}
A.jV.prototype={
$1(a){return a.b},
$S:46}
A.jW.prototype={
$1(a){return a.c},
$S:13}
A.jX.prototype={
$1(a){return a.d},
$S:13}
A.jY.prototype={
$1(a){return a.e},
$S:22}
A.jZ.prototype={
$1(a){return a.f},
$S:22}
A.k_.prototype={
$1(a){return a.r},
$S:13}
A.k0.prototype={
$1(a){return a.y},
$S:22}
A.jP.prototype={
$1(a){return a.a},
$S:45}
A.jQ.prototype={
$1(a){return a.b},
$S:46}
A.jS.prototype={
$1(a){return a.a.toLowerCase()===this.a.a.toLowerCase()},
$S:83}
A.kB.prototype={
$0(){var s=this.a.c
s.toString
return A.K(s)},
$S:0}
A.kb.prototype={
$0(){var s,r=this.b.a.toLowerCase(),q=this.a.a.b
q===$&&A.b()
s=q.c.h(0,r.toLowerCase())
if(s==null)throw A.c(A.q("Table '"+r+"' does not exist."))
return s},
$S:80}
A.kc.prototype={
$0(){var s=J.bG(this.a.b,new A.ka(),t.W)
s=A.r(s,s.$ti.i("u.E"))
return s},
$S:76}
A.ka.prototype={
$1(a){return A.K(a)},
$S:14}
A.kd.prototype={
$0(){var s=this.b.a,r=s.c
r===$&&A.b()
return A.aO(r,s.a,this.a.a.a)},
$S:5}
A.kg.prototype={
$0(){var s=this.b.a,r=s.c
r===$&&A.b()
return A.aO(r,s.a,this.a.a.a)},
$S:5}
A.kh.prototype={
$0(){var s=this.b.a,r=s.c
r===$&&A.b()
return A.aO(r,s.a,this.a.a.a)},
$S:5}
A.ki.prototype={
$2(a,b){var s,r,q=this,p=q.a,o=p.a.dx
o===$&&A.b()
s=B.b.ac(o,a.toLowerCase())
if(s!==-1){r=A.K(b).$1(q.c)
p=p.a
q.d[s]=q.b.e4(r,p.c[s],p.b[s])}},
$S:71}
A.kj.prototype={
$0(){return this.a.a.toLowerCase()},
$S:19}
A.kk.prototype={
$1(a){return B.a.V(a).toLowerCase()},
$S:7}
A.kl.prototype={
$1(a){return a.toLowerCase()===this.a},
$S:8}
A.km.prototype={
$0(){var s=this.a.a,r=s.c
r===$&&A.b()
return A.aO(r,s.a,this.b.a)},
$S:5}
A.kn.prototype={
$0(){var s=this.b.a,r=s.c
r===$&&A.b()
return new A.bQ(r,this.a.a.a,s.a)},
$S:66}
A.ke.prototype={
$0(){var s=this.b.a,r=s.c
r===$&&A.b()
return A.aO(r,s.a,this.a.a.a)},
$S:5}
A.kf.prototype={
$0(){return this.a.a.toLowerCase()},
$S:19}
A.k2.prototype={
$0(){var s=this.a.a,r=s.c
r===$&&A.b()
return A.aO(r,s.a,this.b.a)},
$S:5}
A.k3.prototype={
$0(){return A.K(this.a.d)},
$S:0}
A.k4.prototype={
$0(){var s,r,q,p=A.o(t.N,t.S)
for(s=0,r=this.a,q=r.b,r=r.a+".";s<q.length;++s){J.aY(p,r+q[s],s)
J.aY(p,q[s],s)}return p},
$S:23}
A.k5.prototype={
$0(){var s=this.a.b
s.toString
return A.K(s)},
$S:0}
A.kC.prototype={
$1(a){return a.toLowerCase()===this.a.b.toLowerCase()},
$S:8}
A.kD.prototype={
$0(){var s=this.a.a,r=s.c
r===$&&A.b()
return A.aO(r,s.a,this.b.a)},
$S:5}
A.kE.prototype={
$2(a,b){var s=B.c.A(a.a,b.a)
if(!J.az(s,0))return s
return B.c.A(a.b,b.b)},
$S:56}
A.kF.prototype={
$0(){var s,r,q,p=A.o(t.N,t.S)
for(s=0,r=this.a,q=r.b,r=r.a+".";s<q.length;++s){J.aY(p,r+q[s],s)
J.aY(p,q[s],s)}return p},
$S:23}
A.kG.prototype={
$0(){var s=this.a.d
s.toString
return A.K(s)},
$S:0}
A.kH.prototype={
$0(){return A.K(this.a.c)},
$S:0}
A.kI.prototype={
$0(){var s,r,q,p=A.o(t.N,t.S)
for(s=0,r=this.a,q=r.b,r=r.a+".";s<q.length;++s){J.aY(p,r+q[s],s)
J.aY(p,q[s],s)}return p},
$S:23}
A.kJ.prototype={
$0(){return this.a.a.toLowerCase()},
$S:19}
A.kK.prototype={
$1(a){return B.a.V(a).toLowerCase()},
$S:7}
A.kL.prototype={
$1(a){return a.toLowerCase()===this.a},
$S:8}
A.jK.prototype={
$0(){var s=this.a.a,r=s.c
r===$&&A.b()
return A.aO(r,s.a,this.b.a)},
$S:5}
A.ku.prototype={
$2(a,b){this.a.push(A.a([new A.m("ultsql"),new A.m("public"),new A.m(b.a),new A.m("BASE TABLE"),new A.aG(b.d)],t.K))},
$S:24}
A.kv.prototype={
$2(a,b){var s,r,q,p,o,n,m
for(s=b.b,r=this.a,q=b.a,p=b.c,o=t.K,n=0;n<s.length;n=m){m=n+1
r.push(A.a([new A.m("ultsql"),new A.m("public"),new A.m(q),new A.m(s[n]),A.v(m),new A.m(p[n].b.toUpperCase()),new A.m("YES")],o))}},
$S:24}
A.kw.prototype={
$1(a){return new A.ai(new A.H(A.a([a],t.s)),null)},
$S:60}
A.kz.prototype={
$1(a){var s=this
if(a instanceof A.dG)return!0
if(a instanceof A.cE)return s.$1(a.a)
if(a instanceof A.dK)return s.$1(a.a)
if(a instanceof A.bW)return s.$1(a.a)
if(a instanceof A.dP)return s.$1(a.a)
if(a instanceof A.cK)return s.$1(a.a)
if(a instanceof A.ds)return s.$1(a.a)||s.$1(a.b)
if(a instanceof A.dt)return s.$1(a.a)
if(a instanceof A.dr)return s.$1(a.a)
return!1},
$S:58}
A.kx.prototype={
$0(){var s=0,r=A.b6(t.V),q,p=this,o,n,m,l,k,j,i,h,g,f,e
var $async$$0=A.b7(function(a,b){if(a===1)return A.b3(b,r)
for(;;)switch(s){case 0:f=p.a
e=f.a.c
e===$&&A.b()
e.bb()
e=p.b
s=3
return A.ar(new A.ky().$1(e),$async$$0)
case 3:e.N()
o=A.a([],t.F)
n=A.a([],t.s)
for(m=t.K,l=!1;;){k=e.K()
if(k==null)break
if(!l){n=k.gZ().aO(0)
l=!0}j=A.a([],m)
for(i=n.length,h=0;h<n.length;n.length===i||(0,A.n)(n),++h){g=k.h(0,n[h])
j.push(g==null?new A.d():g)}o.push(j)}e.L()
f.cU(p.c,n,o)
q=new A.B(n,o,""+o.length+" rows returned.",B.f)
s=1
break
case 1:return A.b4(q,r)}})
return A.b5($async$$0,r)},
$S:40}
A.ky.prototype={
fD(a){var s=0,r=A.b6(t.H),q=this
var $async$$1=A.b7(function(b,c){if(b===1)return A.b3(c,r)
for(;;)switch(s){case 0:s=a instanceof A.dG?2:4
break
case 2:s=5
return A.ar(a.cs(),$async$$1)
case 5:s=3
break
case 4:s=a instanceof A.cE?6:8
break
case 6:s=9
return A.ar(q.$1(a.a),$async$$1)
case 9:s=7
break
case 8:s=a instanceof A.dK?10:12
break
case 10:s=13
return A.ar(q.$1(a.a),$async$$1)
case 13:s=11
break
case 12:s=a instanceof A.bW?14:16
break
case 14:s=17
return A.ar(q.$1(a.a),$async$$1)
case 17:s=15
break
case 16:s=a instanceof A.dP?18:20
break
case 18:s=21
return A.ar(q.$1(a.a),$async$$1)
case 21:s=19
break
case 20:s=a instanceof A.cK?22:24
break
case 22:s=25
return A.ar(q.$1(a.a),$async$$1)
case 25:s=23
break
case 24:s=a instanceof A.ds?26:28
break
case 26:s=29
return A.ar(q.$1(a.a),$async$$1)
case 29:s=30
return A.ar(q.$1(a.b),$async$$1)
case 30:s=27
break
case 28:s=a instanceof A.dt?31:33
break
case 31:s=34
return A.ar(q.$1(a.a),$async$$1)
case 34:s=32
break
case 33:s=a instanceof A.dr?35:36
break
case 35:s=37
return A.ar(q.$1(a.a),$async$$1)
case 37:case 36:case 32:case 27:case 23:case 19:case 15:case 11:case 7:case 3:return A.b4(null,r)}})
return A.b5($async$$1,r)},
$1(a){return this.fD(a)},
$S:59}
A.jM.prototype={
$0(){return A.K(this.a.b)},
$S:0}
A.k1.prototype={
$0(){return A.K(this.a.a)},
$S:0}
A.kA.prototype={
$2(a,b){var s=B.b.R(b.b,", "),r=b.d?"Columnar":"Row"
this.a.push(A.a([new A.m(b.a),new A.m(s),new A.m(r)],t.K))},
$S:24}
A.jR.prototype={
$0(){return new A.bs(null,null,0)},
$S:32}
A.kr.prototype={
$0(){var s=this.a.c
s.toString
return A.K(s)},
$S:0}
A.ks.prototype={
$1(a){var s=a.a
return s.toLowerCase()==="others"||B.a.E(J.x(this.a).toLowerCase(),s.toLowerCase())},
$S:61}
A.kt.prototype={
$0(){var s=this.a.d
s.toString
return B.b.gH(s)},
$S:62}
A.k8.prototype={
$0(){return A.K(this.a.a)},
$S:0}
A.k9.prototype={
$0(){return A.K(this.a.a)},
$S:0}
A.kM.prototype={
$0(){return A.K(this.a.a)},
$S:0}
A.kN.prototype={
$0(){return A.a([],t.f0)},
$S:63}
A.kO.prototype={
$2(a,b){var s,r,q=a.d,p=q.length,o=b.d,n=o.length,m=p<n?p:n
for(s=0;s<m;++s){r=B.h.A(q[s],o[s])
if(r!==0)return r}return B.c.A(p,n)},
$S:64}
A.kP.prototype={
$0(){return new A.bs(null,null,0)},
$S:32}
A.kQ.prototype={
$0(){return new A.bs(null,null,0)},
$S:32}
A.jL.prototype={
$0(){var s=this.a.a,r=s.c
r===$&&A.b()
return A.aO(r,s.a,this.b.a)},
$S:5}
A.k6.prototype={
$0(){return A.K(this.a.b)},
$S:0}
A.k7.prototype={
$0(){return A.K(this.a.c)},
$S:0}
A.bk.prototype={}
A.o4.prototype={
$1(a){return A.cw(B.a.V(a))},
$S:16}
A.cs.prototype={}
A.i_.prototype={}
A.lM.prototype={
$1(a){var s,r,q,p,o=this,n=o.a
if(n.b)return o.b.$1(a)
s=n.a
if(s!=null){r=a.h(0,s)
if(r!=null)return r}s=o.c
if(a.F(s)){n.a=s
n=a.h(0,s)
n.toString
return n}q=s.toLowerCase()
for(s=a.gZ(),s=s.gJ(s);s.p();){p=s.gD()
if(p.toLowerCase()===q){n.a=p
s=a.h(0,p)
s.toString
return s}}n.b=!0
return o.b.$1(a)},
$S:1}
A.lb.prototype={
$1(a){var s,r,q,p,o=$.eB
if(o==null)return new A.d()
$.cQ.push(a)
try{s=o.aA(this.a.b)
if(s!=null){r=s.gfu()
if(t.j.b(r)){if(J.O(r)===0){q=A.a([],t.K)
return new A.aP(q)}if(J.O(r)===1&&J.Y(r,0).length===1){q=J.Y(r,0)[0]
return q}q=r
p=A.z(q).i("h<1,k>")
q=A.r(new A.h(q,new A.la(),p),p.i("u.E"))
return new A.aP(q)}}return new A.d()}finally{if($.cQ.length!==0)$.cQ.pop()}},
$S:1}
A.la.prototype={
$1(a){var s=J.X(a)
return s.gaa(a)?t.r.a(s.h(a,0)):new A.d()},
$S:53}
A.lc.prototype={
$1(a){var s,r,q,p=this,o=null,n=p.a.$1(a)
if(n instanceof A.M){s=n.ga2()
if(t.f.b(s))r=s.h(0,p.b)
else if(t.j.b(s)){q=A.a4(p.b,o)
r=q!=null&&q>=0&&q<J.O(s)?J.Y(s,q):o}else r=o
if(r==null)return new A.d()
if(p.c)if(typeof r=="string")return new A.m(r)
else return new A.m(B.o.bB(r))
else if(A.fJ(r))return A.v(r)
else if(typeof r=="number")return new A.j(r)
else if(typeof r=="number")return new A.j(r)
else if(A.fI(r))return A.v(r?1:0)
else return new A.M(r,o)}return new A.d()},
$S:1}
A.ld.prototype={
$1(a){return new A.d()},
$S:1}
A.lo.prototype={
$1(a){return this.a},
$S:1}
A.lz.prototype={
$1(a){return this.a},
$S:68}
A.lE.prototype={
$1(a){return new A.d()},
$S:31}
A.lF.prototype={
$1(a){return new A.M(!0,null)},
$S:52}
A.lG.prototype={
$1(a){return new A.M(!1,null)},
$S:52}
A.lH.prototype={
$1(a){var s,r,q,p,o,n,m,l,k,j,i,h,g=this,f=g.a,e=f.a
if(e!=null&&a instanceof A.aN){s=a.a[e]
if(g.b&&s instanceof A.M&&f.c<g.c.length)return s.aY(B.b.ad(g.c,f.c))
return s}e=f.b
if(e!=null){if(a instanceof A.aN){r=a.b.h(0,e)
if(r!=null){f.a=r
s=a.a[r]
if(g.b&&s instanceof A.M&&f.c<g.c.length)return s.aY(B.b.ad(g.c,f.c))
return s}}s=a.h(0,f.b)
if(s==null)return new A.d()
if(g.b&&s instanceof A.M&&f.c<g.c.length)return s.aY(B.b.ad(g.c,f.c))
return s}q=B.b.R(g.d.b,".")
if(a.F(q)){f.b=q
f.c=g.c.length
f=a.h(0,q)
f.toString
return f}p=q.toLowerCase()
for(e=a.gZ(),e=e.gJ(e);e.p();){o=e.gD()
if(o.toLowerCase()===p){f.b=o
f.c=g.c.length
e=a.h(0,o)
e.toString
return e}}e=g.c
if(e.length>=2){n=(e[0]+"."+e[1]).toLowerCase()
for(o=a.gZ(),o=o.gJ(o);o.p();){m=o.gD()
if(m.toLowerCase()===n){f.b=m
f.c=2
o=a.h(0,m)
o.toString
if(e.length>2&&o instanceof A.M)return o.aY(B.b.ad(e,2))
return o}}l=A.p6(q)
if(l!=null)return l
k=e[1].toLowerCase()
for(o=a.gZ(),o=o.gJ(o),m="."+k;o.p();){j=o.gD()
i=j.toLowerCase()
if(i===k||B.a.B(i,m)){f.b=j
f.c=2
o=a.h(0,j)
o.toString
if(e.length>2&&o instanceof A.M)return o.aY(B.b.ad(e,2))
return o}}}h=e[0].toLowerCase()
for(o=a.gZ(),o=o.gJ(o),m="."+h;o.p();){j=o.gD()
i=j.toLowerCase()
if(i===h||B.a.B(i,m)){f.b=j
f.c=1
o=a.h(0,j)
o.toString
if(e.length>1&&o instanceof A.M)return o.aY(B.b.ad(e,1))
return o}}l=A.p6(q)
if(l!=null)return l
return new A.d()},
$S:1}
A.lI.prototype={
$1(a){return J.rJ(this.a.$1(a),this.b.$1(a))},
$S:1}
A.lJ.prototype={
$1(a){return J.rM(this.a.$1(a),this.b.$1(a))},
$S:1}
A.le.prototype={
$1(a){return J.rL(this.a.$1(a),this.b.$1(a))},
$S:1}
A.lf.prototype={
$1(a){return J.rK(this.a.$1(a),this.b.$1(a))},
$S:1}
A.lg.prototype={
$1(a){var s=a.h(0,this.a)
return s==null?new A.d():s},
$S:1}
A.lh.prototype={
$1(a){var s=this.a.$1(a),r=this.b.$1(a),q=s instanceof A.p
if(q&&r instanceof A.p)return A.v(B.c.a7(s.a,r.a))
else if(q&&r instanceof A.j)return new A.j(B.c.a7(s.a,r.a))
else{q=s instanceof A.j
if(q&&r instanceof A.p)return new A.j(B.h.a7(s.a,r.a))
else if(q&&r instanceof A.j)return new A.j(B.h.a7(s.a,r.a))}return new A.d()},
$S:1}
A.li.prototype={
$1(a){return this.a.$1(a).aJ(this.b.$1(a))},
$S:1}
A.lj.prototype={
$1(a){var s,r=this.a.$1(a),q=this.b.$1(a),p=r instanceof A.p
if(p&&q instanceof A.p)return r.a===q.a?$.U():$.R()
s=r instanceof A.j
if(s&&q instanceof A.j)return r.a===q.a?$.U():$.R()
if(p&&q instanceof A.j)return r.a===q.a?$.U():$.R()
if(s&&q instanceof A.p)return r.a===q.a?$.U():$.R()
if(r instanceof A.m&&q instanceof A.m)return r.a===q.a?$.U():$.R()
return r.A(0,q)===0?$.U():$.R()},
$S:3}
A.lk.prototype={
$1(a){var s,r=this.a.$1(a),q=this.b.$1(a),p=r instanceof A.p
if(p&&q instanceof A.p)return r.a!==q.a?$.U():$.R()
s=r instanceof A.j
if(s&&q instanceof A.j)return r.a!==q.a?$.U():$.R()
if(p&&q instanceof A.j)return r.a!==q.a?$.U():$.R()
if(s&&q instanceof A.p)return r.a!==q.a?$.U():$.R()
if(r instanceof A.m&&q instanceof A.m)return r.a!==q.a?$.U():$.R()
return r.A(0,q)!==0?$.U():$.R()},
$S:3}
A.ll.prototype={
$1(a){var s,r=this.a.$1(a),q=this.b.$1(a),p=r instanceof A.p
if(p&&q instanceof A.p)return r.a<q.a?$.U():$.R()
s=r instanceof A.j
if(s&&q instanceof A.j)return r.a<q.a?$.U():$.R()
if(p&&q instanceof A.j)return r.a<q.a?$.U():$.R()
if(s&&q instanceof A.p)return r.a<q.a?$.U():$.R()
return r.A(0,q)<0?$.U():$.R()},
$S:3}
A.lm.prototype={
$1(a){var s,r=this.a.$1(a),q=this.b.$1(a),p=r instanceof A.p
if(p&&q instanceof A.p)return r.a<=q.a?$.U():$.R()
s=r instanceof A.j
if(s&&q instanceof A.j)return r.a<=q.a?$.U():$.R()
if(p&&q instanceof A.j)return r.a<=q.a?$.U():$.R()
if(s&&q instanceof A.p)return r.a<=q.a?$.U():$.R()
return r.A(0,q)<=0?$.U():$.R()},
$S:3}
A.ln.prototype={
$1(a){var s,r=this.a.$1(a),q=this.b.$1(a),p=r instanceof A.p
if(p&&q instanceof A.p)return r.a>q.a?$.U():$.R()
s=r instanceof A.j
if(s&&q instanceof A.j)return r.a>q.a?$.U():$.R()
if(p&&q instanceof A.j)return r.a>q.a?$.U():$.R()
if(s&&q instanceof A.p)return r.a>q.a?$.U():$.R()
return r.A(0,q)>0?$.U():$.R()},
$S:3}
A.lp.prototype={
$1(a){var s,r=this.a.$1(a),q=this.b.$1(a),p=r instanceof A.p
if(p&&q instanceof A.p)return r.a>=q.a?$.U():$.R()
s=r instanceof A.j
if(s&&q instanceof A.j)return r.a>=q.a?$.U():$.R()
if(p&&q instanceof A.j)return r.a>=q.a?$.U():$.R()
if(s&&q instanceof A.p)return r.a>=q.a?$.U():$.R()
return r.A(0,q)>=0?$.U():$.R()},
$S:3}
A.lq.prototype={
$1(a){var s=J.x(this.b.$1(a)),r=J.x(this.c.$1(a)),q=this.a
if(r!==q.a){q.a=r
q.b=A.aI(r,!0)}q=q.b
if(q==null)q=null
else{q=q.b
q=q.test(s)}return q===!0?$.U():$.R()},
$S:3}
A.lr.prototype={
$1(a){var s,r,q,p,o,n,m,l,k,j,i,h,g=this
if(!(g.b!=null)){s=g.a
if(s.b==null){r=s.b=J.x(g.c.$1(a))
s.d=s.e=s.f=s.r=!1
q=!1
p=!1
o=!1
n=!1
if(!B.a.E(r,"_")&&!B.a.E(r,"\\")){m=B.a.U(r,"%")
l=B.a.B(r,"%")
k=m?1:0
j=r.length
if(!B.a.E(B.a.O(r,k,j-(l?1:0)),"%")){q=m&&l&&j>=2
if(q){s.r=!0
s.w=B.a.O(r,1,j-1).toLowerCase()}else{o=m&&!l&&j>=1
if(o){s.e=!0
s.w=B.a.az(r,1).toLowerCase()}else{p=!m
k=p&&l&&j>=1
if(k){s.f=!0
s.w=B.a.O(r,0,j-1).toLowerCase()
p=n}else{p=p&&!l
if(p){s.d=!0
s.w=r.toLowerCase()}else s.c=null}n=p
p=k}}}else s.c=null}else s.c=null
if(s.c==null&&!q&&!p&&!o&&!n){q=A.iq(r)
q=A.T(q,"\\%","%")
q=A.T(q,"\\_","_")
q=A.T(q,"%",".*")
s.c=A.aI("^"+A.T(q,"_",".")+"$",!1)}}}i=g.d.$1(a)
if(i instanceof A.d)return $.R()
h=A.r_(i.l(0))
s=g.a
if(s.r)return B.a.E(h,s.w)?$.U():$.R()
if(s.f)return B.a.U(h,s.w)?$.U():$.R()
if(s.e)return B.a.B(h,s.w)?$.U():$.R()
if(s.d)return h===s.w?$.U():$.R()
s=s.c.b
return s.test(h)?$.U():$.R()},
$S:3}
A.ls.prototype={
$1(a){return A.wf(J.x(this.a.$1(a)),J.x(this.b.$1(a)))?$.U():$.R()},
$S:3}
A.lt.prototype={
$1(a){var s,r,q,p,o=this.a.$1(a),n=this.b.$1(a)
if(n instanceof A.aP){r=n.a
q=r.length
p=0
for(;;){if(!(p<r.length)){s=!1
break}if(o.A(0,r[p])===0){s=!0
break}r.length===q||(0,A.n)(r);++p}return A.v(s?1:0)}else return A.v(o.A(0,n)===0?1:0)},
$S:3}
A.lu.prototype={
$1(a){var s,r,q=this.a.$1(a),p=this.b.$1(a)
if(!(q instanceof A.p&&q.a===1))s=q instanceof A.j&&q.a>0
else s=!0
if(!(p instanceof A.p&&p.a===1))r=p instanceof A.j&&p.a>0
else r=!0
return s&&r?$.U():$.R()},
$S:3}
A.lv.prototype={
$1(a){var s,r,q=this.a.$1(a),p=this.b.$1(a)
if(!(q instanceof A.p&&q.a===1))s=q instanceof A.j&&q.a>0
else s=!0
if(!(p instanceof A.p&&p.a===1))r=p instanceof A.j&&p.a>0
else r=!0
return s||r?$.U():$.R()},
$S:3}
A.lw.prototype={
$1(a){return new A.d()},
$S:31}
A.lx.prototype={
$1(a){return new A.ia(A.bY(a.a),A.bY(a.b))},
$S:72}
A.ly.prototype={
$1(a){var s,r,q,p,o,n,m
for(s=this.a,r=s.length,q=0;q<s.length;s.length===r||(0,A.n)(s),++q){p=s[q]
o=p.a.$1(a)
n=!0
if(!(o instanceof A.p&&o.a===1))if(!(o instanceof A.j&&o.a>0)){m=o instanceof A.m&&o.a.toLowerCase()==="true"
n=m}if(n)return p.b.$1(a)}s=this.b
if(s!=null)return s.$1(a)
return new A.d()},
$S:1}
A.lA.prototype={
$1(a){var s,r,q,p=this.a.$1(a)
if(p instanceof A.d)return new A.d()
switch(this.b.a){case 0:if(p instanceof A.p)return p
if(p instanceof A.aG)return A.v(p.a?1:0)
s=A.a4(p.l(0),null)
return A.v(s==null?0:s)
case 1:case 9:if(p instanceof A.j)return p
if(p instanceof A.a8)return p
if(p instanceof A.p)return new A.j(p.a)
s=A.aH(p.l(0))
return new A.j(s==null?0:s)
case 2:return new A.m(p.l(0))
case 5:if(p instanceof A.aG)return p
if(p instanceof A.p)return new A.aG(p.a!==0)
r=p.l(0).toLowerCase()
return new A.aG(r==="true"||r==="1"||r==="yes"||r==="t")
case 6:return new A.bp(p.l(0))
case 7:q=A.bA(p.l(0))
return new A.bo(q==null?new A.aw(Date.now(),0,!1):q)
case 8:if(p instanceof A.b0)return p
return new A.b0(new Uint8Array(A.bx(B.x.aB(p.l(0)))))
case 3:case 4:return p}},
$S:1}
A.lB.prototype={
$1(a){return A.bY(a)},
$S:14}
A.lC.prototype={
$1(g9){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2,b3,b4,b5,b6,b7,b8,b9,c0,c1,c2,c3,c4,c5,c6,c7,c8,c9,d0,d1,d2,d3,d4,d5,d6,d7,d8,d9,e0,e1,e2,e3,e4,e5,e6,e7,e8,e9,f0,f1,f2,f3,f4,f5,f6,f7,f8,f9,g0,g1,g2,g3,g4=this,g5=null,g6="0",g7="euclidean",g8=g4.a
if(g9.F(g8)){g8=g9.h(0,g8)
g8.toString
return g8}m=g8.toLowerCase()
if(g9.F(m)){g8=g9.h(0,m)
g8.toString
return g8}for(g8=g9.gZ(),g8=g8.gJ(g8);g8.p();){l=g8.gD()
if(l.toLowerCase()===m){g8=g9.h(0,l)
g8.toString
return g8}}g8=g4.b
if(g8==="concat"){k=new A.cn("")
for(g8=g4.c,l=g8.length,j=0;j<g8.length;g8.length===l||(0,A.n)(g8),++j){i=g8[j].$1(g9)
if(!(i instanceof A.d)){h=i.l(0)
k.a+=h}}g8=k.a
return new A.m(g8.charCodeAt(0)==0?g8:g8)}if(g8==="concat_ws"&&g4.c.length>=2){g8=g4.c
g=J.x(g8[0].$1(g9))
k=new A.cn("")
for(f=!0,e=1;e<g8.length;++e){i=g8[e].$1(g9)
if(!(i instanceof A.d)){if(!f)k.a+=g
l=i.l(0)
k.a+=l
f=!1}}g8=k.a
return new A.m(g8.charCodeAt(0)==0?g8:g8)}if(g8==="length"||g8==="len"){g8=g4.c
if(g8.length===0)return new A.d()
i=B.b.cu(g8,g9)
return i instanceof A.d?new A.d():A.v(i.l(0).length)}if(g8==="upper"){g8=g4.c
if(g8.length===0)return new A.d()
i=B.b.cu(g8,g9)
return i instanceof A.d?new A.d():new A.m(i.l(0).toUpperCase())}if(g8==="lower"){g8=g4.c
if(g8.length===0)return new A.d()
i=B.b.cu(g8,g9)
return i instanceof A.d?new A.d():new A.m(i.l(0).toLowerCase())}if(g8==="trim"){g8=g4.c
if(g8.length===0)return new A.d()
i=B.b.cu(g8,g9)
return i instanceof A.d?new A.d():new A.m(B.a.V(i.l(0)))}if(g8==="substring"||g8==="substr"){g8=g4.c
if(g8.length===0)return new A.d()
d=J.x(g8[0].$1(g9))
l=d.length
if(l===0)return new A.m("")
c=g8.length>1?g8[1].$1(g9):A.v(1)
if(c instanceof A.p)h=c.a
else{h=A.a4(c.l(0),g5)
if(h==null)h=1}b=B.c.du(h-1,0,l)
if(g8.length>2){a=g8[2].$1(g9)
if(a instanceof A.p)a0=a.a
else{g8=A.a4(a.l(0),g5)
a0=g8==null?l:g8}return new A.m(B.a.O(d,b,B.c.du(b+a0,b,l)))}return new A.m(B.a.az(d,b))}if(g8==="coalesce"){for(g8=g4.c,l=g8.length,j=0;j<g8.length;g8.length===l||(0,A.n)(g8),++j){i=g8[j].$1(g9)
if(!(i instanceof A.d))return i}return new A.d()}if(g8==="nullif"&&g4.c.length>=2){g8=g4.c
a1=g8[0].$1(g9)
a2=g8[1].$1(g9)
if(a1.aw(0,a2)||a1.l(0)===a2.l(0))return new A.d()
return a1}if(g8==="greatest"){for(g8=g4.c,l=g8.length,a3=g5,j=0;j<g8.length;g8.length===l||(0,A.n)(g8),++j){i=g8[j].$1(g9)
if(!(i instanceof A.d))if(a3==null||i.A(0,a3)>0)a3=i}return a3==null?new A.d():a3}if(g8==="least"){for(g8=g4.c,l=g8.length,a4=g5,j=0;j<g8.length;g8.length===l||(0,A.n)(g8),++j){i=g8[j].$1(g9)
if(!(i instanceof A.d))if(a4==null||i.A(0,a4)<0)a4=i}return a4==null?new A.d():a4}if(g8==="typeof"&&g4.c.length!==0)return new A.m(g4.c[0].$1(g9).gae().b.toUpperCase())
if(g8==="now"||g8==="current_timestamp")return new A.bo(new A.aw(Date.now(),0,!1))
if(g8==="current_date"){a5=new A.aw(Date.now(),0,!1)
return new A.m(""+A.b2(a5)+"-"+B.a.a1(B.c.l(A.bB(a5)),2,g6)+"-"+B.a.a1(B.c.l(A.bI(a5)),2,g6))}if(g8==="gen_random_uuid"||g8==="uuid"){a6=J.dv(16,t.S)
for(a7=0;a7<16;++a7)a6[a7]=B.cw.cA(256)
a6[6]=a6[6]&15|64
a6[8]=a6[8]&63|128
a8=new A.h(a6,new A.l3(),A.z(a6).i("h<1,e>")).dE(0)
return new A.bp(B.a.O(a8,0,8)+"-"+B.a.O(a8,8,12)+"-"+B.a.O(a8,12,16)+"-"+B.a.O(a8,16,20)+"-"+B.a.az(a8,20))}if(g8==="generate_series"){g8=g4.c
l=A.z(g8).i("h<1,k>")
a9=A.r(new A.h(g8,new A.l4(g9),l),l.i("u.E"))
g8=a9.length!==0
if(g8&&a9[0] instanceof A.p)b0=t.A.a(a9[0]).a
else{l=A.a4(g8?a9[0].l(0):"1",g5)
b0=l==null?1:l}g8=a9.length>1
if(g8&&a9[1] instanceof A.p)b1=t.A.a(a9[1]).a
else{l=A.a4(g8?a9[1].l(0):"10",g5)
b1=l==null?10:l}g8=a9.length>2
if(g8&&a9[2] instanceof A.p)b2=t.A.a(a9[2]).a
else{l=A.a4(g8?a9[2].l(0):"1",g5)
b2=l==null?1:l}b3=A.a([],t.K)
if(b2>0)for(e=b0;e<=b1;e+=b2)b3.push(A.v(e))
else if(b2<0)for(e=b0;e>=b1;e+=b2)b3.push(A.v(e))
return new A.aP(b3)}if(g8==="ifnull"||g8==="nvl"){g8=g4.c
if(g8.length<2)return new A.d()
a1=g8[0].$1(g9)
return!(a1 instanceof A.d)?a1:g8[1].$1(g9)}if(g8==="date"){g8=g4.c
a5=A.bA(g8.length===0?new A.aw(Date.now(),0,!1).bt():J.x(g8[0].$1(g9)))
if(a5==null)a5=new A.aw(Date.now(),0,!1)
return new A.m(""+A.b2(a5)+"-"+B.a.a1(B.c.l(A.bB(a5)),2,g6)+"-"+B.a.a1(B.c.l(A.bI(a5)),2,g6))}if(g8==="time"){g8=g4.c
a5=A.bA(g8.length===0?new A.aw(Date.now(),0,!1).bt():J.x(g8[0].$1(g9)))
if(a5==null)a5=new A.aw(Date.now(),0,!1)
return new A.m(B.a.a1(B.c.l(A.dJ(a5)),2,g6)+":"+B.a.a1(B.c.l(A.eQ(a5)),2,g6)+":"+B.a.a1(B.c.l(A.eR(a5)),2,g6))}if(g8==="datetime"){g8=g4.c
b4=g8.length===0?g5:J.x(g8[0].$1(g9))
if(b4!=null&&b4!=="now"){g8=A.bA(b4)
a5=g8==null?new A.aw(Date.now(),0,!1):g8}else a5=new A.aw(Date.now(),0,!1)
return new A.m(""+A.b2(a5)+"-"+B.a.a1(B.c.l(A.bB(a5)),2,g6)+"-"+B.a.a1(B.c.l(A.bI(a5)),2,g6)+" "+B.a.a1(B.c.l(A.dJ(a5)),2,g6)+":"+B.a.a1(B.c.l(A.eQ(a5)),2,g6)+":"+B.a.a1(B.c.l(A.eR(a5)),2,g6))}if(g8==="abs"&&g4.c.length!==0){i=g4.c[0].$1(g9)
if(i instanceof A.p)return A.v(Math.abs(i.a))
if(i instanceof A.j)return new A.j(Math.abs(i.a))
if(i instanceof A.a8)return new A.a8(Math.abs(i.a))
b5=A.re(i.l(0))
if(b5==null)b5=0
return A.fJ(b5)?A.v(Math.abs(b5)):new A.j(Math.abs(b5))}if(g8==="round"&&g4.c.length!==0){g8=g4.c
i=g8[0].$1(g9)
if(g8.length>1){g8=A.a4(J.x(g8[1].$1(g9)),g5)
b6=g8==null?0:g8}else b6=0
b7=A.aH(i.l(0))
if(b7==null)b7=0
if(b6===0)return A.v(B.h.ft(b7))
b8=Math.pow(10,b6)
return new A.j(B.h.ft(b7*b8)/b8)}if((g8==="ceil"||g8==="ceiling")&&g4.c.length!==0){b7=A.aH(J.x(g4.c[0].$1(g9)))
return A.v(B.h.iu(b7==null?0:b7))}if(g8==="floor"&&g4.c.length!==0){b7=A.aH(J.x(g4.c[0].$1(g9)))
return A.v(B.h.dz(b7==null?0:b7))}if((g8==="power"||g8==="pow")&&g4.c.length>=2){g8=g4.c
b9=A.aH(J.x(g8[0].$1(g9)))
if(b9==null)b9=0
c0=A.aH(J.x(g8[1].$1(g9)))
if(c0==null)c0=0
return new A.j(Math.pow(b9,c0))}if(g8==="sqrt"&&g4.c.length!==0){b7=A.aH(J.x(g4.c[0].$1(g9)))
if(b7==null)b7=0
return new A.j(Math.sqrt(b7))}if(g8==="mod"&&g4.c.length>=2){g8=g4.c
c1=A.a4(J.x(g8[0].$1(g9)),g5)
if(c1==null)c1=0
c2=A.a4(J.x(g8[1].$1(g9)),g5)
return A.v(B.c.a7(c1,c2==null?1:c2))}if(g8==="sign"&&g4.c.length!==0){b7=A.aH(J.x(g4.c[0].$1(g9)))
if(b7==null)b7=0
if(b7>0)return A.v(1)
if(b7<0)return A.v(-1)
return A.v(0)}if(g8==="replace"&&g4.c.length>=3){g8=g4.c
d=J.x(g8[0].$1(g9))
c3=J.x(g8[1].$1(g9))
c4=J.x(g8[2].$1(g9))
return new A.m(A.T(d,c3,c4))}if(g8==="lpad"&&g4.c.length>=2){g8=g4.c
d=J.x(g8[0].$1(g9))
c5=A.a4(J.x(g8[1].$1(g9)),g5)
if(c5==null)c5=d.length
return new A.m(B.a.a1(d,c5,g8.length>2?J.x(g8[2].$1(g9)):" "))}if(g8==="rpad"&&g4.c.length>=2){g8=g4.c
d=J.x(g8[0].$1(g9))
c5=A.a4(J.x(g8[1].$1(g9)),g5)
if(c5==null)c5=d.length
return new A.m(B.a.iZ(d,c5,g8.length>2?J.x(g8[2].$1(g9)):" "))}if(g8==="reverse"&&g4.c.length!==0)return new A.m(new A.eY(A.a(J.x(g4.c[0].$1(g9)).split(""),t.s),t.bJ).dE(0))
if(g8==="regexp_like"&&g4.c.length>=2){g8=g4.c
d=J.x(g8[0].$1(g9))
g8=A.aI(J.x(g8[1].$1(g9)),!0)
return new A.aG(g8.b.test(d))}if(g8==="split_part"&&g4.c.length>=3){g8=g4.c
d=J.x(g8[0].$1(g9))
c6=J.x(g8[1].$1(g9))
g8=A.a4(J.x(g8[2].$1(g9)),g5)
c7=(g8==null?1:g8)-1
c8=d.split(c6)
if(c7>=0&&c7<c8.length)return new A.m(c8[c7])
return new A.m("")}if(g8==="initcap"&&g4.c.length!==0)return new A.m(new A.h(A.a(J.x(g4.c[0].$1(g9)).split(" "),t.s),new A.l5(),t.e).R(0," "))
if(g8==="date_add"&&g4.c.length>=2){g8=g4.c
b4=J.x(g8[0].$1(g9))
c9=A.a4(J.x(g8[1].$1(g9)),g5)
if(c9==null)c9=0
a5=A.bA(b4)
if(a5==null)a5=new A.aw(Date.now(),0,!1)
d0=a5.dY(A.iY(c9,0).a)
return new A.m(""+A.b2(d0)+"-"+B.a.a1(B.c.l(A.bB(d0)),2,g6)+"-"+B.a.a1(B.c.l(A.bI(d0)),2,g6))}if(g8==="date_sub"&&g4.c.length>=2){g8=g4.c
b4=J.x(g8[0].$1(g9))
c9=A.a4(J.x(g8[1].$1(g9)),g5)
if(c9==null)c9=0
a5=A.bA(b4)
if(a5==null)a5=new A.aw(Date.now(),0,!1)
d1=a5.dY(0-A.iY(c9,0).a)
return new A.m(""+A.b2(d1)+"-"+B.a.a1(B.c.l(A.bB(d1)),2,g6)+"-"+B.a.a1(B.c.l(A.bI(d1)),2,g6))}if(g8==="date_trunc"&&g4.c.length>=2){g8=g4.c
d2=J.x(g8[0].$1(g9)).toLowerCase()
a5=A.bA(J.x(g8[1].$1(g9)))
if(a5==null)a5=new A.aw(Date.now(),0,!1)
if(d2==="year")return new A.m(""+A.b2(a5)+"-01-01 00:00:00")
if(d2==="month")return new A.m(""+A.b2(a5)+"-"+B.a.a1(B.c.l(A.bB(a5)),2,g6)+"-01 00:00:00")
if(d2==="day")return new A.m(""+A.b2(a5)+"-"+B.a.a1(B.c.l(A.bB(a5)),2,g6)+"-"+B.a.a1(B.c.l(A.bI(a5)),2,g6)+" 00:00:00")
if(d2==="hour")return new A.m(""+A.b2(a5)+"-"+B.a.a1(B.c.l(A.bB(a5)),2,g6)+"-"+B.a.a1(B.c.l(A.bI(a5)),2,g6)+" "+B.a.a1(B.c.l(A.dJ(a5)),2,g6)+":00:00")
return new A.m(a5.bt())}if(g8==="extract"&&g4.c.length>=2){g8=g4.c
d3=J.x(g8[0].$1(g9)).toLowerCase()
a5=A.bA(J.x(g8[1].$1(g9)))
if(a5==null)a5=new A.aw(Date.now(),0,!1)
if(d3==="year")return A.v(A.b2(a5))
if(d3==="month")return A.v(A.bB(a5))
if(d3==="day")return A.v(A.bI(a5))
if(d3==="hour")return A.v(A.dJ(a5))
if(d3==="minute")return A.v(A.eQ(a5))
if(d3==="second")return A.v(A.eR(a5))
return A.v(0)}if(g8==="json_array"){g8=g4.c
l=A.z(g8).i("h<1,k>")
g8=A.r(new A.h(g8,new A.l6(g9),l),l.i("u.E"))
return A.r5(g8)}if(g8==="json_object"){g8=g4.c
l=A.z(g8).i("h<1,k>")
g8=A.r(new A.h(g8,new A.l7(g9),l),l.i("u.E"))
return A.r6(g8)}if(g8==="version")return new A.m("ULTSQL v1.0.12 (Pure-Dart Converged Database Engine)")
if((g8==="position"||g8==="strpos")&&g4.c.length>=2){g8=g4.c
d4=J.x(g8[0].$1(g9))
d5=B.a.ac(J.x(g8[1].$1(g9)),d4)
return A.v(d5===-1?0:d5+1)}if(g8==="strftime"){g8=g4.c
if(g8.length<2)return new A.d()
d6=J.x(g8[0].$1(g9))
b4=J.x(g8[1].$1(g9))
if(b4==="now")a5=new A.aw(Date.now(),0,!1)
else{g8=A.bA(b4)
a5=g8==null?new A.aw(Date.now(),0,!1):g8}g8=B.c.l(A.b2(a5))
g8=A.T(d6,"%Y",g8)
l=B.a.a1(B.c.l(A.bB(a5)),2,g6)
g8=A.T(g8,"%m",l)
l=B.a.a1(B.c.l(A.bI(a5)),2,g6)
g8=A.T(g8,"%d",l)
l=B.a.a1(B.c.l(A.dJ(a5)),2,g6)
g8=A.T(g8,"%H",l)
l=B.a.a1(B.c.l(A.eQ(a5)),2,g6)
g8=A.T(g8,"%M",l)
l=B.a.a1(B.c.l(A.eR(a5)),2,g6)
return new A.m(A.T(g8,"%S",l))}if(g8==="in_list"){g8=g4.c
l=A.z(g8).i("h<1,k>")
a9=A.r(new A.h(g8,new A.l8(g9),l),l.i("u.E"))
return new A.aP(a9)}if(g8==="st_point"&&g4.c.length===2){g8=g4.c
d7=g8[0].$1(g9)
d8=g8[1].$1(g9)
if(d7 instanceof A.j)d9=d7.a
else d9=d7 instanceof A.p?d7.a:0
if(d8 instanceof A.j)e0=d8.a
else e0=d8 instanceof A.p?d8.a:0
return new A.m("POINT("+A.D(d9)+" "+A.D(e0)+")")}if(g8==="st_distance"&&g4.c.length===2){g8=g4.c
e1=g8[0].$1(g9)
e2=g8[1].$1(g9)
if(e1 instanceof A.m&&e2 instanceof A.m){e3=A.oU(e1.a)
e4=A.oU(e2.a)
if(e3!=null&&e4!=null)return new A.j(Math.sqrt(Math.pow(e3[0]-e4[0],2)+Math.pow(e3[1]-e4[1],2)))}return new A.d()}if(g8==="st_contains"&&g4.c.length===2){g8=g4.c
e5=g8[0].$1(g9)
e6=g8[1].$1(g9)
if(e5 instanceof A.m&&e6 instanceof A.m){e7=A.tu(e5.a)
e8=A.oU(e6.a)
if(e7!=null&&e8!=null){for(e9=e7.length-1,f0=!1,e=0;e<e7.length;f1=e+1,e9=e,e=f1)if(J.Y(e7[e],1)>e8[1]!==J.Y(e7[e9],1)>e8[1]&&e8[0]<(J.Y(e7[e9],0)-J.Y(e7[e],0))*(e8[1]-J.Y(e7[e],1))/(J.Y(e7[e9],1)-J.Y(e7[e],1))+J.Y(e7[e],0))f0=!f0
return A.v(f0?1:0)}}return new A.d()}l=$.eB
if(l!=null){s=l
l=s.a.b
l===$&&A.b()
r=l.y.h(0,g8.toLowerCase())
if(r!=null){g8=g4.c
l=A.z(g8).i("h<1,k>")
a9=A.r(new A.h(g8,new A.l9(g9),l),l.i("u.E"))
q=A.Z(s.c,t.N,t.r)
s.c.v(0)
e=0
for(;;){g8=r.c
g8===$&&A.b()
if(!(e<g8.length))break
g8=r.c
g8===$&&A.b()
f2=g8[e]
f3=e<a9.length?a9[e]:new A.d()
s.c.k(0,f2.a,f3);++e}p=new A.d()
try{g8=r.e
g8===$&&A.b()
l=g8.length
j=0
for(;j<g8.length;g8.length===l||(0,A.n)(g8),++j){o=g8[j]
s.aA(o)}}catch(f4){g8=A.aV(f4)
if(g8 instanceof A.dN){n=g8
p=n.a}else throw f4}finally{s.c.v(0)
s.c.X(0,q)}return p}}if(g8==="time_bucket"&&g4.c.length===2){g8=g4.c
f5=g8[0].$1(g9)
f6=g8[1].$1(g9)
if(f5 instanceof A.m&&f6 instanceof A.m){f7=f5.a
a5=A.bA(f6.a)
if(a5!=null){if(B.a.B(f7,"m")){g8=A.a4(A.T(f7,"m",""),g5)
f8=(g8==null?0:g8)*60*1000}else if(B.a.B(f7,"h")){g8=A.a4(A.T(f7,"h",""),g5)
f8=(g8==null?0:g8)*60*60*1000}else if(B.a.B(f7,"s")){g8=A.a4(A.T(f7,"s",""),g5)
f8=(g8==null?0:g8)*1000}else f8=0
if(f8>0){g8=B.c.b_(a5.a,f8)
l=a5.c
return new A.m(new A.aw(A.oF(g8*f8,0,l),0,l).bt())}}}return new A.d()}if(g8==="vector_distance"){l=g4.c.length
l=l===2||l===3}else l=!1
if(l){g8=g4.c
a1=g8[0].$1(g9)
a2=g8[1].$1(g9)
if(g8.length===3){f9=g8[2].$1(g9)
g0=f9 instanceof A.m?f9.a.toLowerCase():g7}else g0=g7
if(a1 instanceof A.m){g1=A.q3(a1.a)
a1=g1==null?a1:g1}if(a2 instanceof A.m){g2=A.q3(a2.a)
a2=g2==null?a2:g2}if(a1 instanceof A.a5&&a2 instanceof A.a5)switch(g0){case"cosine":return new A.j(a1.cm(a2))
case"dot":return new A.j(a1.cp(a2))
case"euclidean":default:return new A.j(a1.co(a2))}return new A.d()}if(g8==="cast"&&g4.c.length===2){b4=g4.c[0].$1(g9)
g3=J.x(t.gV.a(g4.d.c[1]).b)
if(b4 instanceof A.d)return new A.d()
if(g3==="DataType.text")return new A.m(b4.l(0))
else if(g3==="DataType.integer"){if(b4 instanceof A.p)return b4
if(b4 instanceof A.j)return A.v(B.h.bd(b4.a))
g8=A.a4(b4.l(0),g5)
return A.v(g8==null?0:g8)}else if(g3==="DataType.double"){if(b4 instanceof A.j)return b4
if(b4 instanceof A.p)return new A.j(b4.a)
g8=A.aH(b4.l(0))
return new A.j(g8==null?0:g8)}return new A.d()}if(g8==="json_set"&&g4.c.length===3){g8=g4.c
return A.r8(g8[0].$1(g9),g8[1].$1(g9),g8[2].$1(g9))}if(g8==="json_remove"&&g4.c.length===2){g8=g4.c
return A.r7(g8[0].$1(g9),g8[1].$1(g9))}return new A.d()},
$S:1}
A.l3.prototype={
$1(a){return B.a.a1(B.c.fw(a,16),2,"0")},
$S:6}
A.l4.prototype={
$1(a){return a.$1(this.a)},
$S:9}
A.l5.prototype={
$1(a){return a.length===0?"":a[0].toUpperCase()+B.a.az(a,1).toLowerCase()},
$S:7}
A.l6.prototype={
$1(a){return a.$1(this.a)},
$S:9}
A.l7.prototype={
$1(a){return a.$1(this.a)},
$S:9}
A.l8.prototype={
$1(a){return a.$1(this.a)},
$S:9}
A.l9.prototype={
$1(a){return a.$1(this.a)},
$S:9}
A.lD.prototype={
$1(a){return new A.d()},
$S:31}
A.lL.prototype={
$1(a){return A.cw(B.a.V(a))},
$S:16}
A.lK.prototype={
$1(a){var s=J.X(a)
return A.a([A.ik(s.h(a,0)),A.ik(s.h(a,1))],t.n)},
$S:151}
A.mh.prototype={}
A.oq.prototype={
$0(){return A.oB(this.a)},
$S:30}
A.or.prototype={
$0(){return A.oB(this.a)},
$S:30}
A.dG.prototype={
N(){this.z=0},
cs(){var s=0,r=A.b6(t.H),q,p=this,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2,b3,b4
var $async$cs=A.b7(function(b5,b6){if(b5===1)return A.b3(b6,r)
for(;;)switch(s){case 0:b4=p.f
if(b4===0){p.y=A.a([],t.b)
s=1
break}o=A.a([],t.dL)
for(n=p.r,m=t.c,l=p.w,k=l==null,j=p.a,i=p.c,h=p.b,g=p.d,f=p.e,e=p.x,d=e!=null,c=0;B.c.cM(c,n);){b=B.c.b_(b4,n)
a=c<B.c.a7(b4,n)?c:B.c.a7(b4,n)
a0=c*b+a;++c
a=B.c.b_(b4,n)
b=c<B.c.a7(b4,n)?c:B.c.a7(b4,n)
a1=c*a+b
if(a0>=a1)continue
a2=new A.mh(j,a0,a1,i,h,g,f,l,e)
if(!k||d)o.push(A.pZ(new A.me(a2),m))
else o.push(A.pZ(new A.mf(a2),m))}s=3
return A.ar(A.ti(o,m),$async$cs)
case 3:a3=b6
b4=!k||d
n=t.b_
if(b4){b4=t.r
a4=A.o(b4,n)
for(n=J.as(a3),m=t.eM,l=t.A,k=t.N;n.p();)for(j=J.as(n.gD());j.p();){i=j.gD()
h=i.h(0,"group_key")
h.toString
if(!a4.F(h))a4.k(0,h,A.Z(i,k,b4))
else{h=a4.h(0,h)
h.toString
for(g=e.length,a5=0;a5<e.length;e.length===g||(0,A.n)(e),++a5){a6=e[a5]
a7=a6.b
if(a7==null)a7=A.S(a6.a)
a8=a6.a
if(a8 instanceof A.af){a9=a8.b.toLowerCase()
f=h.h(0,a7)
f.toString
d=i.h(0,a7)
d.toString
if(a9==="count"||a9==="sum"){b=f instanceof A.p
if(b&&d instanceof A.p)h.k(0,a7,A.v(f.a+d.a))
else{a=f instanceof A.j
if(a||d instanceof A.j){if(b)b0=f.a
else b0=a?f.a:0
if(d instanceof A.p)b1=d.a
else b1=d instanceof A.j?d.a:0
h.k(0,a7,new A.j(b0+b1))}}}else if(a9==="avg"){m.a(f)
m.a(d)
b=a7+"_count"
a=l.a(h.h(0,b))
b2=l.a(i.h(0,b))
h.k(0,a7,new A.j(f.a+d.a))
h.k(0,b,A.v(a.a+b2.a))}else if(a9==="min"){b=f instanceof A.d
if(!b&&!(d instanceof A.d)){if(!(f.A(0,d)<0))f=d
h.k(0,a7,f)}else if(b)h.k(0,a7,d)}else if(a9==="max"){b=f instanceof A.d
if(!b&&!(d instanceof A.d)){if(!(f.A(0,d)>0))f=d
h.k(0,a7,f)}else if(b)h.k(0,a7,d)}}}}}for(b4=a4.$ti,n=new A.ao(a4,a4.r,a4.e,b4.i("ao<2>"));n.p();){k=n.d
k.S(0,"group_key")
for(j=e.length,a5=0;a5<e.length;e.length===j||(0,A.n)(e),++a5){a6=e[a5]
a8=a6.a
if(a8 instanceof A.af&&a8.b.toLowerCase()==="avg"){a7=a6.b
if(a7==null)a7=A.S(a8)
b3=m.a(k.h(0,a7))
i=a7+"_count"
h=l.a(k.h(0,i)).a
k.k(0,a7,h>0?new A.j(b3.a/h):new A.d())
k.S(0,i)}}}b4=b4.i("b1<2>")
b4=A.r(new A.b1(a4,b4),b4.i("F.E"))
p.y=b4}else{b4=J.rS(a3,new A.mg(),n)
b4=A.r(b4,b4.$ti.i("F.E"))
p.y=b4}case 1:return A.b4(q,r)}})
return A.b5($async$cs,r)},
K(){var s,r=this.y
if(r==null)throw A.c(A.fb("ParallelScanNode not executed. Call executeParallelScan() first."))
s=this.z
if(s>=r.length)return null
this.z=s+1
return r[s]},
L(){this.y=null},
G(a){return B.a.P("  ",a)+"ParallelScanNode(table: "+this.b.a+", workers: "+A.D(this.r)+")"},
a6(){return this.G(0)}}
A.me.prototype={
$0(){return A.wi(this.a)},
$S:17}
A.mf.prototype={
$0(){return A.wj(this.a)},
$S:17}
A.mg.prototype={
$1(a){return a},
$S:78}
A.P.prototype={}
A.of.prototype={
$1(a){var s=J.X(a)
return s.gaa(a)?t.r.a(s.h(a,0)):new A.d()},
$S:53}
A.og.prototype={
$1(a){return A.bM(a,this.a)},
$S:21}
A.hG.prototype={
fR(a,b,c,d){var s,r,q,p,o,n,m=this
m.f!==$&&A.bd()
s=m.f=m.c
r=A.z(s).i("h<1,e>")
r=A.r(new A.h(s,new A.mL(m),r),r.i("u.E"))
m.r!==$&&A.bd()
m.r=r
q=A.z(s).i("h<1,e>")
q=A.r(new A.h(s,new A.mM(m),q),q.i("u.E"))
m.w!==$&&A.bd()
m.w=q
m.x!==$&&A.bd()
p=m.x=A.o(t.N,t.S)
for(o=0;o<s.length;++o){n=s[o]
p.k(0,r[o],n)
p.k(0,q[o],n)}},
N(){var s,r=this,q=r.a,p=q.a,o=p.ga5(),n=o==null,m=n?null:o.a
if(m==null)m=0
n=n?null:o.b
if(n==null)n=B.u
s=r.f
s===$&&A.b()
r.e=q.c3(n,r.d,m,r.b.b.length,s,p.ax)},
K(){var s,r=this.e
if(r==null)return null
if(!r.p())return null
r=this.e.ax
r.toString
s=this.x
s===$&&A.b()
return new A.aN(r,s)},
L(){this.e=null},
G(a){var s=B.a.P("  ",a),r=A.D(this.c)
return s+"RowScanNode(table: "+this.b.a+(", projected: "+r)+")"},
a6(){return this.G(0)}}
A.mL.prototype={
$1(a){var s=this.a.b
return s.a+"."+s.b[a]},
$S:6}
A.mM.prototype={
$1(a){return this.a.b.b[a]},
$S:6}
A.dR.prototype={
N(){this.a.N()},
K(){var s,r,q,p,o,n,m,l=this.a.K()
if(l==null)return null
s=A.o(t.N,t.r)
for(r=l.gbZ(),r=r.gJ(r),q=this.b,p=q!=null;r.p();){o=r.gD()
n=o.a
o=o.b
s.k(0,n,o)
m=B.b.gW(n.split("."))
s.k(0,m,o)
if(p)s.k(0,q.toLowerCase()+"."+m,o)}return s},
L(){this.a.L()},
G(a){var s=B.a.P("  ",a),r=this.b,q=r!=null?" AS "+r:""
return s+"SubqueryScanNode"+q+"\n"+this.a.G(a+1)},
a6(){return this.G(0)}}
A.hb.prototype={
N(){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1=this
a1.d=0
a1.c=A.a([],t.b)
if($.eB==null)return
p=a1.a
o=t.N
n=t.r
s=A.bM(p,A.o(o,n))
r=[]
if(s instanceof A.aP)r=s.a
else if(s instanceof A.M){m=t.j
if(m.b(s.ga2()))r=m.a(s.ga2())}else if(s instanceof A.m)try{q=B.o.ag(s.a)
if(t.j.b(q))r=q}catch(l){}for(m=J.as(r),p=p.b,k=a1.b,j=k!=null,i=t.j,h=t.f;m.p();){g=m.gD()
f=A.o(o,n)
if(h.b(g))g.a0(0,new A.j8(a1,f))
else if(i.b(g))for(e=J.X(g),d=0;d<e.gt(g);++d){c="col"+d
b=A.cd(e.h(g,d))
f.k(0,c,b)
if(j)f.k(0,k.toLowerCase()+"."+c,b)
else f.k(0,p.toLowerCase()+"."+c,b)}else{e=g instanceof A.M
if(e){a=g.a
a=h.b(a==null?g.a=B.o.ag(g.gaR()):a)}else a=!1
if(a){e=g.a
h.a(e==null?g.a=B.o.ag(g.gaR()):e).a0(0,new A.j9(a1,f))}else if(g instanceof A.aP)for(e=g.a,d=0;d<e.length;++d){c="col"+d
b=e[d]
f.k(0,c,b)
if(j)f.k(0,k.toLowerCase()+"."+c,b)
else f.k(0,p.toLowerCase()+"."+c,b)}else{if(e){e=g.a
e=i.b(e==null?g.a=B.o.ag(g.gaR()):e)}else e=!1
if(e){e=g.a
a0=i.a(e==null?g.a=B.o.ag(g.gaR()):e)
for(e=J.X(a0),d=0;d<e.gt(a0);++d){c="col"+d
b=A.cd(e.h(a0,d))
f.k(0,c,b)
if(j)f.k(0,k.toLowerCase()+"."+c,b)
else f.k(0,p.toLowerCase()+"."+c,b)}}else{b=g instanceof A.k?g:A.cd(g)
f.k(0,"value",b)
if(j)f.k(0,k.toLowerCase()+".value",b)
else f.k(0,p.toLowerCase()+".value",b)}}}a1.c.push(f)}},
K(){var s=this.c
if(s==null||this.d>=s.length)return null
return s[this.d++]},
L(){this.c=null},
G(a){var s=B.a.P("  ",a),r=this.b,q=r!=null?" AS "+r:""
return s+"FunctionScanNode("+A.S(this.a)+q+")"},
a6(){return this.G(0)}}
A.j8.prototype={
$2(a,b){var s,r,q=J.x(a),p=A.cd(b),o=this.b
o.k(0,q,p)
s=this.a
r=s.b
if(r!=null)o.k(0,r.toLowerCase()+"."+q,p)
else o.k(0,s.a.b.toLowerCase()+"."+q,p)},
$S:4}
A.j9.prototype={
$2(a,b){var s,r,q=J.x(a),p=A.cd(b),o=this.b
o.k(0,q,p)
s=this.a
r=s.b
if(r!=null)o.k(0,r.toLowerCase()+"."+q,p)
else o.k(0,s.a.b.toLowerCase()+"."+q,p)},
$S:4}
A.h7.prototype={
N(){this.b=A.a([],t.b)
this.c=0
var s=this.a.d.h(0,"filename")
if(s==null)throw A.c(A.q("Foreign table requires filename in options"))
if(B.a.U(s,"'")&&B.a.B(s,"'"))B.a.O(s,1,s.length-1)
return},
K(){return null},
L(){this.b=null},
G(a){return B.a.P("  ",a)+"ForeignScanNode("+this.a.a+")"},
a6(){return this.G(0)}}
A.fX.prototype={
fO(a,b,c){var s=this,r=s.c,q=A.z(r).i("h<1,e>"),p=q.i("u.E"),o=A.r(new A.h(r,new A.iN(s),q),p)
s.f!==$&&A.bd()
s.f=o
r=A.r(new A.h(r,new A.iO(s),q),p)
s.r!==$&&A.bd()
s.r=r},
N(){var s,r,q,p,o,n=this,m=n.d
B.b.v(m)
for(s=n.c,r=s.length,q=n.a,p=0;p<s.length;s.length===r||(0,A.n)(s),++p){o=q.cN(s[p])
m.push(new A.c8(o.a(),o.$ti.i("c8<1>")))}s=m.length
n.e=s!==0
for(p=0;p<m.length;m.length===s||(0,A.n)(m),++p)if(!m[p].p())n.e=!1},
K(){var s,r,q,p,o,n,m,l=this
if(!l.e||l.d.length===0)return null
s=l.w
s.v(0)
for(r=l.c,q=l.d,p=0;p<r.length;++p){o=q[p]
n=o.b
m=l.f
m===$&&A.b()
s.k(0,m[p],n)
m=l.r
m===$&&A.b()
s.k(0,m[p],n)
if(!o.p())l.e=!1}return s},
L(){B.b.v(this.d)},
G(a){var s=this.c
return B.a.P("  ",a)+"ColumnScanNode(table: "+this.b.a+", columns: ["+new A.h(s,new A.iP(this),A.z(s).i("h<1,e>")).R(0,", ")+"])"},
a6(){return this.G(0)}}
A.iN.prototype={
$1(a){var s=this.a.b
return s.a+"."+s.b[a]},
$S:6}
A.iO.prototype={
$1(a){return this.a.b.b[a]},
$S:6}
A.iP.prototype={
$1(a){return this.a.b.b[a]},
$S:6}
A.he.prototype={
fP(a,b,c,d,e,f){var s,r,q=this,p=q.f,o=A.z(p).i("h<1,e>"),n=o.i("u.E"),m=A.r(new A.h(p,new A.jG(q),o),n)
q.Q!==$&&A.bd()
q.Q=m
o=A.r(new A.h(p,new A.jH(q),o),n)
q.as!==$&&A.bd()
q.as=o
q.at!==$&&A.bd()
n=q.at=A.o(t.N,t.S)
for(s=0;s<p.length;++s){r=p[s]
n.k(0,m[s],r)
n.k(0,o[s],r)}p=A.a9(q.b.b.length,new A.d(),!1,t.r)
q.ax!==$&&A.bd()
q.ax=p},
N(){var s=this
s.r=null
s.w=0
s.y=s.x=null},
hN(a,b,c){var s,r,q,p,o,n,m
if(c<12)return!0
s=b.getUint32(0,!1)
r=b.getUint32(4,!1)
q=a.a
p=q.ga5()
o=p==null
n=o?null:p.a
if(n==null)n=0
m=o?null:p.b
if(m==null)m=B.u
return q.ax.aC(s,r,n,m)},
hL(a,b,c,d){if(c<12)return A.qj(b,0,c,d)
return A.qj(b,12,c-12,d)},
K(){var s,r,q,p,o,n,m,l,k,j,i=this
if(i.r==null){s=i.c
s.av()
s=i.r=s.cP(i.d,i.e)
if(i.f.length!==0&&s.length>250)B.b.aq(s,new A.jI())}for(s=i.a,r=s.a,q=s.c+"/"+s.b+".db";p=i.w,o=i.r,p<o.length;){i.w=p+1
n=o[p]
p=i.y
o=n.a
if(p!==o){if(i.x!=null){p.toString
r.u(q,p,!1)}i.x=r.C(q,o)
i.y=o}p=i.x
p.toString
m=A.ab(p,n.b)
if(m!=null){l=A.at(m,0,null)
p=m.length
if(i.hN(s,l,p)){r=i.ax
r===$&&A.b()
B.b.bC(r,0,r.length,new A.d())
for(q=i.f,k=0;k<q.length;++k){j=q[k]
r[j]=i.hL(s,l,p,j)}s=i.at
s===$&&A.b()
return new A.aN(r,s)}}}if(i.x!=null){s=i.y
s.toString
r.u(q,s,!1)
i.y=i.x=null}return null},
L(){var s,r,q=this
if(q.x!=null){s=q.a
r=q.y
r.toString
s.a.u(s.c+"/"+s.b+".db",r,!1)
q.y=q.x=null}q.r=null},
G(a){var s,r=this,q=B.a.P("  ",a),p=B.b.gW(r.c.b.split("/")),o=A.T(p,".idx","")
p=r.d
p=A.D(p==null?"-\u221e":p)
s=r.e
return q+"IndexScanNode(table: "+r.b.a+", index: "+o+", range: ["+p+", "+A.D(s==null?"\u221e":s)+"])"},
a6(){return this.G(0)}}
A.jG.prototype={
$1(a){var s=this.a.b
return s.a+"."+s.b[a]},
$S:6}
A.jH.prototype={
$1(a){return this.a.b.b[a]},
$S:6}
A.jI.prototype={
$2(a,b){var s=B.c.A(a.a,b.a)
if(s!==0)return s
return B.c.A(a.b,b.b)},
$S:56}
A.cE.prototype={
gd8(){var s=this.c
s===$&&A.b()
return s},
N(){return this.a.N()},
K(){var s,r,q
for(s=this.a;;){r=s.K()
if(r==null)return null
q=this.d9(r)
if(q instanceof A.p&&q.a===1)return r
if(q instanceof A.j&&q.a>0)return r
if(q instanceof A.aG&&q.a)return r}},
L(){return this.a.L()},
G(a){var s=B.a.P("  ",a),r=this.a.G(a+1)
return s+"FilterNode(condition: "+A.S(this.b)+")\n"+r},
a6(){return this.G(0)},
d9(a){return this.gd8().$1(a)}}
A.dK.prototype={
fQ(a,b){var s=this.b,r=A.z(s).i("h<1,k(w<e,k>)>")
s=A.r(new A.h(s,new A.mn(),r),r.i("u.E"))
this.c!==$&&A.bd()
this.c=s},
N(){return this.a.N()},
K(){var s,r,q,p,o,n,m,l,k=this.a.K()
if(k==null)return null
s=A.o(t.N,t.r)
for(r=this.b,q=0;q<r.length;++q){p=r[q]
o=p.a
n=o instanceof A.H
if(n&&B.b.gH(o.b)==="*"){s.X(0,k)
continue}m=this.c
m===$&&A.b()
l=m[q].$1(k)
m=p.b
if(m!=null)s.k(0,m,l)
else if(n)s.k(0,B.b.R(o.b,"."),l)
else s.k(0,A.S(o),l)}return s},
L(){return this.a.L()},
G(a){var s=B.a.P("  ",a),r=this.a.G(a+1),q=this.b
return s+"ProjectNode(projections: ["+new A.h(q,new A.mo(),A.z(q).i("h<1,e>")).R(0,", ")+"])\n"+r},
a6(){return this.G(0)}}
A.mn.prototype={
$1(a){return A.K(a.a)},
$S:79}
A.mo.prototype={
$1(a){var s=a.b
return s==null?A.S(a.a):s},
$S:48}
A.d6.prototype={
dN(a0,a1,a2){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a=this
for(s=a1.length,r=a.x,q=a.w,p=a.r,o=a.e,n=a.f,m=a.d,l=a.c,k=a.b,j=0;j<a1.length;a1.length===s||(0,A.n)(a1),++j){i=a1[j]
h=i.a
g=i.b
if(g==null)g=A.S(h)
if(h instanceof A.af){f=h.b.toLowerCase()
if(f==="count"){e=h.c
if(e.length!==0){e=e[0]
e=e instanceof A.H&&B.b.gH(e.b)==="*"}else e=!0
if(e){e=k.h(0,g)
k.k(0,g,(e==null?0:e)+1)}else if(!(a2.h(0,i).$1(a0) instanceof A.d)){e=k.h(0,g)
k.k(0,g,(e==null?0:e)+1)}}else if(f==="sum"){d=a2.h(0,i).$1(a0)
if(d instanceof A.p){e=l.h(0,g)
if(e==null)e=0
l.k(0,g,e+d.a)
e=m.h(0,g)
m.k(0,g,e===!0)}else if(d instanceof A.j){e=l.h(0,g)
if(e==null)e=0
l.k(0,g,e+d.a)
m.k(0,g,!0)}}else if(f==="avg"){d=a2.h(0,i).$1(a0)
if(d instanceof A.p){e=n.h(0,g)
if(e==null)e=0
n.k(0,g,e+d.a)
e=o.h(0,g)
o.k(0,g,(e==null?0:e)+1)}else if(d instanceof A.j){e=n.h(0,g)
if(e==null)e=0
n.k(0,g,e+d.a)
e=o.h(0,g)
o.k(0,g,(e==null?0:e)+1)}}else if(f==="min"){d=a2.h(0,i).$1(a0)
if(!(d instanceof A.d)){c=p.h(0,g)
if(c==null||d.A(0,c)<0)p.k(0,g,d)}}else if(f==="max"){d=a2.h(0,i).$1(a0)
if(!(d instanceof A.d)){b=q.h(0,g)
if(b==null||d.A(0,b)>0)q.k(0,g,d)}}else if(r.h(0,g)==null)r.k(0,g,a2.h(0,i).$1(a0))}else if(r.h(0,g)==null)r.k(0,g,a2.h(0,i).$1(a0))}},
iC(a0){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b=this,a=A.o(t.N,t.r)
for(s=a0.length,r=b.x,q=b.w,p=b.r,o=b.f,n=b.e,m=b.d,l=b.c,k=b.b,j=0;j<a0.length;a0.length===s||(0,A.n)(a0),++j){i=a0[j]
h=i.a
g=i.b
if(g==null)g=A.S(h)
if(h instanceof A.af){f=h.b.toLowerCase()
if(f==="count"){e=k.h(0,g)
a.k(0,g,A.v(e==null?0:e))}else if(f==="sum"){d=l.h(0,g)
if(d==null)a.k(0,g,new A.d())
else{e=m.h(0,g)
a.k(0,g,e===!0?new A.j(d):A.v(B.h.bd(d)))}}else if(f==="avg"){c=n.h(0,g)
if(c==null)c=0
d=o.h(0,g)
if(d==null)d=0
a.k(0,g,c>0?new A.j(d/c):new A.d())}else if(f==="min"){e=p.h(0,g)
a.k(0,g,e==null?new A.d():e)}else if(f==="max"){e=q.h(0,g)
a.k(0,g,e==null?new A.d():e)}else{e=r.h(0,g)
a.k(0,g,e==null?new A.d():e)}}else{e=r.h(0,g)
a.k(0,g,e==null?new A.d():e)}}return a}}
A.bW.prototype={
N(){this.a.N()
this.e=null
this.f=0},
i4(){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2,b3,b4,b5,b6,b7,b8,b9,c0,c1,c2,c3,c4,c5,c6,c7,c8=this,c9=null,d0={},d1=c8.b,d2=d1 instanceof A.ag
if(d2){s=c8.c
s=s.length===1&&s[0].a instanceof A.af}else s=!1
if(s){s=c8.c
r=t.du.a(s[0].a)
if(r.b.toLowerCase()==="count"){q=r.c
p=q.length
o=!0
if(p!==0)if(p===1){p=q[0]
if(!(p instanceof A.H&&B.b.gH(p.b)==="*")){q=q[0]
q=q instanceof A.ag&&B.a.E(J.x(q.b),"*")}else q=o
o=q}else o=!1
if(o){for(d1=c8.a,n=0;;){if(d1.K()==null)break;++n}m=s[0].b
if(m==null)m="COUNT(*)"
c8.e=A.a([A.a7([m,A.v(n)],t.N,t.r)],t.b)
return}}}if(d2){d1=c8.c
l=d1.length
k=new Int8Array(l)
j=A.a9(l,c9,!1,t.ev)
d2=t.N
i=A.a9(l,"",!1,d2)
h=new Int32Array(l)
g=new Float64Array(l)
f=new Uint8Array(l)
e=new Int32Array(l)
d=new Float64Array(l)
s=t.g1
c=A.a9(l,c9,!1,s)
b=A.a9(l,c9,!1,s)
a=A.a9(l,c9,!1,s)
for(a0=0;a0<l;++a0){a1=d1[a0]
a2=a1.a
s=a1.b
i[a0]=s==null?A.S(a2):s
if(a2 instanceof A.af){a3=a2.b.toLowerCase()
if(a3==="count"){s=a2.c
if(s.length!==0){q=s[0]
q=q instanceof A.H&&B.b.gH(q.b)==="*"}else q=!0
if(q)k[a0]=1
else{k[a0]=2
j[a0]=A.K(s[0])}}else if(a3==="sum"){k[a0]=3
j[a0]=A.K(a2.c[0])}else if(a3==="avg"){k[a0]=4
j[a0]=A.K(a2.c[0])}else if(a3==="min"){k[a0]=5
j[a0]=A.K(a2.c[0])}else if(a3==="max"){k[a0]=6
j[a0]=A.K(a2.c[0])}else{k[a0]=7
s=a2.c
if(s.length!==0)j[a0]=A.K(s[0])}}else{k[a0]=7
j[a0]=A.K(a2)}}for(d1=c8.a;;){a4=d1.K()
if(a4==null)break
for(a0=0;a0<l;++a0){a5=k[a0]
if(a5===1)h[a0]=h[a0]+1
else{a6=j[a0].$1(a4)
if(!(a6 instanceof A.d))if(a5===2)h[a0]=h[a0]+1
else if(a5===3){if(a6 instanceof A.p)g[a0]=g[a0]+a6.a
else if(a6 instanceof A.j){g[a0]=g[a0]+a6.a
f[a0]=1}}else if(a5===4){if(a6 instanceof A.p){d[a0]=d[a0]+a6.a
e[a0]=e[a0]+1}else if(a6 instanceof A.j){d[a0]=d[a0]+a6.a
e[a0]=e[a0]+1}}else if(a5===5){a7=c[a0]
if(a7==null||a6.A(0,a7)<0)c[a0]=a6}else if(a5===6){a8=b[a0]
if(a8==null||a6.A(0,a8)>0)b[a0]=a6}else if(a5===7)if(a[a0]==null)a[a0]=a6}}}a9=A.o(d2,t.r)
for(a0=0;a0<l;++a0){a5=k[a0]
b0=i[a0]
if(a5===1||a5===2)a9.k(0,b0,A.v(h[a0]))
else if(a5===3)a9.k(0,b0,f[a0]===1?new A.j(g[a0]):A.v(B.h.bd(g[a0])))
else if(a5===4){n=e[a0]
a9.k(0,b0,n>0?new A.j(d[a0]/n):new A.d())}else if(a5===5){d1=c[a0]
a9.k(0,b0,d1==null?new A.d():d1)}else if(a5===6){d1=b[a0]
a9.k(0,b0,d1==null?new A.d():d1)}else{d1=a[a0]
a9.k(0,b0,d1==null?new A.d():d1)}}d1=c8.d
b1=d1!=null?A.K(d1):c9
if(b1!=null){b2=b1.$1(a9)
if(b2 instanceof A.p&&b2.a===0||b2 instanceof A.d){c8.e=A.a([],t.b)
return}}c8.e=A.a([a9],t.b)
return}b3=A.o(t.N,t.bf)
d2=t.h
d0.a=A.a([],d2)
if(d1 instanceof A.cF)d0.a=d1.b
else if(d1 instanceof A.dO){b4=d1.b
for(a0=b4.length;a0>=0;--a0)d0.a.push(B.b.bk(b4,0,a0))}else if(d1 instanceof A.dj){b4=d1.b
b5=b4.length
b6=B.c.f_(1,b5)
for(d1=t.U,a0=0;a0<b6;++a0){b7=A.a([],d1)
for(b8=0;b8<b5;++b8)if((a0&B.c.f_(1,b8))>>>0!==0)b7.push(b4[b8])
d0.a.push(b7)}}else d0.a=A.a([A.a([d1],t.U)],d2)
d1=d0.a
d2=A.z(d1).i("h<1,t<k(w<e,k>)>>")
b9=A.r(new A.h(d1,new A.jl(),d2),d2.i("u.E"))
d1=d0.a
d2=A.z(d1).i("h<1,t<e>>")
c0=A.r(new A.h(d1,new A.jm(),d2),d2.i("u.E"))
c1=A.o(t.gY,t.W)
for(d1=c8.c,d2=d1.length,c2=0;c2<d1.length;d1.length===d2||(0,A.n)(d1),++c2){a1=d1[c2]
a2=a1.a
s=a2 instanceof A.af
if(s&&a2.c.length!==0)c1.k(0,a1,A.K(a2.c[0]))
else if(!s)c1.k(0,a1,A.K(a2))}d2=c8.d
b1=d2!=null?A.K(d2):c9
for(d2=t.s,s=c8.a;;){a4=s.K()
if(a4==null)break
for(c3=0;c3<d0.a.length;++c3){c4=b9[c3]
c5=c0[c3]
c6=A.a([],d2)
for(q=J.X(c4),a0=0;a0<q.gt(c4);++a0)c6.push(q.h(c4,a0).$1(a4).l(0))
b3.I(""+c3+":"+B.b.R(c6,","),new A.jn(d0,a4,c5)).dN(a4,d1,c1)}}c8.e=A.a([],t.b)
for(d2=new A.an(b3,b3.$ti.i("an<1,2>")).gJ(0),s=b1!=null;d2.p();){c7=d2.d.b.iC(d1)
if(s){b2=b1.$1(c7)
if(b2 instanceof A.p&&b2.a===0)continue
else if(b2 instanceof A.d)continue}c8.e.push(c7)}},
K(){var s,r,q=this
if(q.e==null)q.i4()
s=q.f
r=q.e
if(s>=r.length)return null
q.f=s+1
return r[s]},
L(){this.a.L()
this.e=null},
G(a){var s,r=this,q=B.a.P("  ",a),p=r.a.G(a+1),o=r.c,n=new A.h(o,new A.jo(),A.z(o).i("h<1,e>")).R(0,", ")
o=r.d
s=o!=null?", having: "+A.S(o):""
return q+"GroupByNode(groupBy: "+A.S(r.b)+", projections: ["+n+"]"+s+")\n"+p},
a6(){return this.G(0)}}
A.jl.prototype={
$1(a){var s=J.bG(a,new A.jk(),t.W)
s=A.r(s,s.$ti.i("u.E"))
return s},
$S:81}
A.jk.prototype={
$1(a){return A.K(a)},
$S:14}
A.jm.prototype={
$1(a){var s=J.bG(a,new A.jj(),t.N)
s=A.r(s,s.$ti.i("u.E"))
return s},
$S:82}
A.jj.prototype={
$1(a){return A.S(a)},
$S:29}
A.jn.prototype={
$0(){var s,r,q,p,o,n,m,l,k=A.q6(this.b,t.N,t.r),j=this.a.a
if(j.length>1){s=A.z(j).i("bV<1,e>")
r=A.q7(new A.bV(j,new A.ji(),s),s.i("F.E"))
for(j=A.i7(r,r.r,A.E(r).c),s=this.c,q=J.X(s),p=j.$ti.c,o=A.E(k).i("aL<1>");j.p();){n=j.d
if(n==null)n=p.a(n)
if(!q.E(s,n))if(k.F(n))k.k(0,n,new A.d())
else{m=B.b.gW(n.split("."))
for(n=new A.aL(k,k.r,k.e,o);n.p();){l=n.d
if(B.b.gW(l.split("."))===m)k.k(0,l,new A.d())}}}}return A.oB(k)},
$S:30}
A.ji.prototype={
$1(a){return J.bG(a,new A.jh(),t.N)},
$S:84}
A.jh.prototype={
$1(a){return A.S(a)},
$S:29}
A.jo.prototype={
$1(a){var s=a.b
return s==null?A.S(a.a):s},
$S:48}
A.ds.prototype={
gbP(){var s=this.y
s===$&&A.b()
return s},
ghQ(){var s=this.z
s===$&&A.b()
return s},
bn(){var s,r,q,p,o,n=A.o(t.N,t.r)
for(s=this.x,r=s.b,q=r.length,s=s.a+".",p=0;p<r.length;r.length===q||(0,A.n)(r),++p){o=r[p]
n.k(0,s+o,new A.d())
n.k(0,o,new A.d())}return n},
N(){var s,r,q,p,o,n,m,l,k,j,i=this
i.a.N()
s=i.b
s.N()
r=i.Q
r.v(0)
q=i.ay
B.b.v(q)
i.ch.v(0)
i.at=i.as=null
i.ax=0
i.CW=null
for(p=!i.f,o=t.N,n=t.r,m=i.r;;){l=s.K()
if(l==null)break
k=i.hR(l).l(0)
j=A.c0(o,n)
j.X(0,l)
J.ae(r.I(k,new A.jq()),j)
if(!p||m)q.push(j)}},
K(){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c=this
for(s=!c.e,r=c.Q,q=c.a,p=c.r,o=c.ay,n=A.z(o).i("aJ<1>"),m=n.i("F.E"),l=!c.f;;){k=c.CW
if(k!=null)if(k.p()){s=c.CW
j=s.d
if(j==null)j=A.E(s).c.a(j)
s=t.N
r=t.r
i=A.o(s,r)
for(q=c.w,p=q.length,h=0;h<q.length;q.length===p||(0,A.n)(q),++h)i.k(0,q[h],new A.d())
s=A.Z(i,s,r)
s.X(0,j)
return s}else return null
k=c.at
if(k!=null&&c.ax<J.O(k)){s=c.at
s.toString
j=J.Y(s,c.ax++)
if(!l||p)c.ch.T(0,j)
s=c.as
s.toString
g=A.Z(s,t.N,t.r)
g.X(0,j)
return g}k=c.as=q.K()
if(k==null){if(!l||p){f=A.r(new A.aJ(o,new A.jp(c),n),m)
c.CW=new J.be(f,f.length,A.z(f).i("be<1>"))
continue}return null}e=c.bQ(k).l(0)
if(r.F(e)){c.at=r.h(0,e)
c.ax=0}else{c.at=null
if(!s||p){d=c.bn()
s=c.as
s.toString
g=A.Z(s,t.N,t.r)
g.X(0,d)
return g}}}},
L(){this.a.L()
this.b.L()
this.Q.v(0)},
G(a){var s=this,r=a+1
return B.a.P("  ",a)+"HashJoinNode(on: "+s.c+" = "+s.d+")\n"+s.a.G(r)+"\n"+s.b.G(r)},
a6(){return this.G(0)},
bQ(a){return this.gbP().$1(a)},
hR(a){return this.ghQ().$1(a)}}
A.jq.prototype={
$0(){return A.a([],t.b)},
$S:17}
A.jp.prototype={
$1(a){return!this.a.ch.E(0,a)},
$S:10}
A.hs.prototype={
gd8(){var s=this.x
s===$&&A.b()
return s},
bn(){var s,r,q,p,o,n=A.o(t.N,t.r)
for(s=this.w,r=s.b,q=r.length,s=s.a+".",p=0;p<r.length;r.length===q||(0,A.n)(r),++p){o=r[p]
n.k(0,s+o,new A.d())
n.k(0,o,new A.d())}return n},
N(){var s,r,q,p,o,n,m=this
m.a.N()
s=m.b
s.N()
r=m.y
B.b.v(r)
m.z.v(0)
m.Q=null
m.as=0
m.at=!1
m.ax=null
for(q=t.N,p=t.r;;){o=s.K()
if(o==null)break
n=A.c0(q,p)
n.X(0,o)
r.push(n)}},
K(){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0=this
for(s=a0.y,r=t.N,q=t.r,p=a0.a,o=!a0.d,n=a0.f,m=A.z(s).i("aJ<1>"),l=m.i("F.E"),k=!a0.e;;){j=a0.ax
if(j!=null)if(j.p()){s=a0.ax
i=s.d
if(i==null)i=A.E(s).c.a(i)
h=A.o(r,q)
for(s=a0.r,p=s.length,g=0;g<s.length;s.length===p||(0,A.n)(s),++g)h.k(0,s[g],new A.d())
s=A.Z(h,r,q)
s.X(0,i)
return s}else return null
if(a0.Q==null){j=p.K()
a0.Q=j
if(j==null){if(!k||n){f=A.r(new A.aJ(s,new A.lY(a0),m),l)
a0.ax=new J.be(f,f.length,A.z(f).i("be<1>"))
continue}return null}a0.as=0
a0.at=!1}while(j=a0.as,j<s.length){a0.as=j+1
i=s[j]
j=a0.Q
j.toString
e=A.Z(j,r,q)
e.X(0,i)
d=a0.d9(e)
if(!(d instanceof A.p&&d.a===1))c=d instanceof A.j&&d.a>0
else c=!0
if(c){s=a0.at=!0
if(k?n:s)a0.z.T(0,i)
return e}}j=a0.Q
j.toString
a0.Q=null
if(!a0.at)b=!o||n
else b=!1
if(b){a=a0.bn()
s=A.Z(j,r,q)
s.X(0,a)
return s}}},
L(){this.a.L()
this.b.L()
B.b.v(this.y)},
G(a){var s=a+1
return B.a.P("  ",a)+"NestedLoopJoinNode(on: "+A.S(this.c)+")\n"+this.a.G(s)+"\n"+this.b.G(s)},
a6(){return this.G(0)},
d9(a){return this.gd8().$1(a)}}
A.lY.prototype={
$1(a){return!this.a.z.E(0,a)},
$S:10}
A.dP.prototype={
ghP(){var s=this.d
s===$&&A.b()
return s},
N(){var s,r,q,p,o,n=this,m=n.a
m.N()
s=n.e
B.b.v(s)
n.f=0
for(r=t.N,q=t.r;;){p=m.K()
if(p==null)break
o=A.c0(r,q)
o.X(0,p)
s.push(o)}B.b.aq(s,new A.mO(n))},
K(){var s=this.f,r=this.e
if(s>=r.length)return null
this.f=s+1
return r[s]},
L(){this.a.L()
B.b.v(this.e)},
G(a){var s=B.a.P("  ",a),r=this.a.G(a+1)
return s+"SortNode(orderBy: "+A.S(this.b)+", asc: "+this.c+")\n"+r},
a6(){return this.G(0)},
ey(a){return this.ghP().$1(a)}}
A.mO.prototype={
$2(a,b){var s=this.a,r=s.ey(a).A(0,s.ey(b))
return s.c?r:-r},
$S:42}
A.hU.prototype={
N(){this.a.N()
this.c=null
this.d=0},
i7(){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2,b3,b4=this,b5=null,b6=t.b,b7=A.a([],b6)
for(s=t.N,r=t.r,q=b4.a;;){p=q.K()
if(p==null)break
o=A.c0(s,r)
o.X(0,p)
b7.push(o)}q=b4.b
o=q.d
n=A.z(o).i("h<1,k(w<e,k>)>")
m=A.r(new A.h(o,new A.ne(),n),n.i("u.E"))
l=A.o(s,t.c)
for(o=b7.length,n=A.z(m).i("h<1,e>"),k=0;k<b7.length;b7.length===o||(0,A.n)(b7),++k){p=b7[k]
j=m.length===0?"":new A.h(m,new A.nf(p),n).R(0,"\x00")
J.ae(l.I(j,new A.ng()),p)}i=q.e
o=i!=null
if(o){h=A.K(i.a)
g=i.b
for(n=new A.ao(l,l.r,l.e,l.$ti.i("ao<2>"));n.p();)J.pI(n.d,new A.nh(h,g))}f=q.b.toLowerCase()
e=A.S(q)
b4.c=A.a([],b6)
for(b6=new A.ao(l,l.r,l.e,l.$ti.i("ao<2>")),n=f==="lag",d=!n,c=f==="dense_rank",b=f==="rank",a=f==="lead",q=q.c;b6.p();){a0=b6.d
if(b){h=o?A.K(i.a):b5
for(a1=J.X(a0),a2=h!=null,a3=b5,a4=1,a5=0;a5<a1.gt(a0);++a5){a6=a1.h(a0,a5)
p=A.c0(s,r)
p.X(0,a6)
if(a2){a7=h.$1(p)
if(a3!=null&&a7.A(0,a3)!==0)a4=a5+1
a3=a7}else a4=a5+1
p.k(0,e,A.v(a4))
b4.c.push(p)}}else if(c){h=o?A.K(i.a):b5
for(a1=J.X(a0),a2=h!=null,a3=b5,a4=1,a5=0;a5<a1.gt(a0);++a5){a6=a1.h(a0,a5)
p=A.c0(s,r)
p.X(0,a6)
if(a2){a7=h.$1(p)
if(a3!=null&&a7.A(0,a3)!==0)++a4
a3=a7}else a4=a5+1
p.k(0,e,A.v(a4))
b4.c.push(p)}}else if(!d||a){a8=q.length!==0?A.S(B.b.gH(q)):""
for(a1=J.X(a0),a2=a8.length!==0,a5=0;a5<a1.gt(a0);++a5){a6=a1.h(a0,a5)
p=A.c0(s,r)
p.X(0,a6)
a9=n?a5-1:a5+1
if(a9>=0&&a9<a1.gt(a0)){b0=a1.h(a0,a9)
b1=new A.d()
if(a2){b2=B.b.gW(a8.split(".")).toLowerCase()
for(a6=b0.gZ(),a6=a6.gJ(a6);a6.p();){b3=a6.gD()
if(B.b.gW(b3.split(".")).toLowerCase()===b2){a6=b0.h(0,b3)
a6.toString
b1=a6
break}}}else b1=J.pG(b0.gaP())?J.e3(b0.gaP()):new A.d()
p.k(0,e,b1)}else p.k(0,e,new A.d())
b4.c.push(p)}}else for(a1=J.X(a0),a5=0;a5<a1.gt(a0);){a2=a1.h(a0,a5)
p=A.c0(s,r)
p.X(0,a2);++a5
p.k(0,e,A.v(a5))
b4.c.push(p)}}},
K(){var s,r,q=this
if(q.c==null)q.i7()
s=q.d
r=q.c
if(s>=r.length)return null
q.d=s+1
return r[s]},
L(){this.a.L()
this.c=null},
G(a){return B.a.P("  ",a)+"WindowNode(func: "+this.b.b+")"},
a6(){return this.G(0)}}
A.ne.prototype={
$1(a){return A.K(a)},
$S:14}
A.nf.prototype={
$1(a){return J.x(a.$1(this.a))},
$S:87}
A.ng.prototype={
$0(){return A.a([],t.b)},
$S:17}
A.nh.prototype={
$2(a,b){var s=this.a,r=s.$1(a).A(0,s.$1(b))
return this.b?r:-r},
$S:42}
A.ha.prototype={
N(){this.r=null
this.w=0},
hs(){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0=this,b1=null
b0.r=A.a([],t.b)
k=b0.f
j=b0.a
i=J.as(k.bf(j))
h=b0.b
for(;;){if(!i.p()){l=b1
break}l=i.gD()
if(l.d==="fts"&&l.c.toLowerCase()===h.toLowerCase())break}i=b0.d
g=l==null?b1:l.a.toLowerCase()
h=g==null?"fts_"+j+"_"+h:g
g=t.N
f=new A.h9(i+"/"+h+".fts",A.o(g,t.eb))
f.av()
h=A.T(b0.c,"'","")
e=f.bj(A.T(h,'"',""))
if(e.length===0)return
d=k.c.h(0,j.toLowerCase().toLowerCase())
if(d==null)return
k=b0.e
j=d.a
c=A.aO(k,i,j)
c.bD()
for(i=e.length,h=c.c+"/"+c.b+".db",b=k.ax,a=d.b,a0=t.r,a1=0;a1<e.length;e.length===i||(0,A.n)(e),++a1){a2=e[a1]
a3=a2.a
s=A.ab(k.C(h,a3),a2.b)
if(s!=null){r=null
try{q=A.aW(s)
p=k.ga5()
o=b
a4=p
a5=a4==null?b1:a4.a
n=a5==null?0:a5
a4=p
a6=a4==null?b1:a4.b
m=a6==null?B.u:a6
if(o.aC(q.a,q.b,n,m))r=A.a0(q.d,b1,b1)}catch(a7){r=A.a0(s,b1,b1)}if(r!=null){a8=A.o(g,a0)
for(a9=0;a9<a.length;++a9){a4=d.dx
a4===$&&A.b()
a8.k(0,j.toLowerCase()+"."+a4[a9],J.Y(r,a9))
a8.k(0,a4[a9],J.Y(r,a9))}b0.r.push(a8)}}k.u(h,a3,!1)}},
K(){var s,r,q=this
if(q.r==null)q.hs()
s=q.w
r=q.r
if(s>=r.length)return null
q.w=s+1
return r[s]},
L(){this.r=null},
G(a){return B.a.P("  ",a)+"FtsScanNode(table: "+this.a+", column: "+this.b+', query: "'+this.c+'")'},
a6(){return this.G(0)}}
A.dA.prototype={
N(){this.b=0},
K(){var s=this.b,r=this.a
if(s>=r.length)return null
this.b=s+1
return r[s]},
L(){},
G(a){return B.a.P("  ",a)+"MemoryScanNode(rowCount: "+this.a.length+")"},
a6(){return this.G(0)}}
A.hE.prototype={
N(){this.a.N()
this.c=null
this.d=0},
hw(){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c=this,b=t.b
c.c=A.a([],b)
s=A.a([],b)
r=c.a
r.N()
for(q=t.N,p=t.r;;){o=r.K()
if(o==null)break
n=c.c
n.toString
n.push(A.Z(o,q,p))
s.push(A.Z(o,q,p))}r.L()
r=t.b_
n=c.b
m=0
for(;;){if(!(s.length!==0&&m<100))break;++m
l=n.$1(new A.dA(A.a6(s,!0,r)))
l.N()
k=A.a([],b)
for(;;){o=l.K()
if(o==null)break
j=A.o(q,p)
i=c.c
if(i.length!==0){i=B.b.gH(i)
h=A.E(i).i("aB<1>")
g=A.r(new A.aB(i,h),h.i("F.E"))
f=J.fP(o.gaP())
for(e=0;e<g.length;++e){d=e<f.length?f[e]:new A.d()
j.k(0,g[e],d)
j.k(0,B.b.gW(g[e].split(".")),d)}}else j.X(0,o)
i=c.c
i.toString
if(!B.b.b2(i,new A.mK(j))){c.c.push(j)
k.push(j)}}l.L()
B.b.v(s)
B.b.X(s,k)}},
K(){var s,r,q=this
if(q.c==null)q.hw()
s=q.d
r=q.c
if(s>=r.length)return null
q.d=s+1
return r[s]},
L(){this.a.L()
this.c=null},
G(a){return B.a.P("  ",a)+"RecursiveCteNode()"},
a6(){return this.G(0)}}
A.mK.prototype={
$1(a){var s,r,q
for(s=this.a,r=new A.aL(s,s.r,s.e,A.E(s).i("aL<1>"));r.p();){q=r.d
if(!J.az(a.h(0,q),s.h(0,q)))return!1}return!0},
$S:10}
A.cK.prototype={
N(){this.a.N()
this.e=this.d=0},
K(){var s,r,q,p=this
for(s=p.c,r=p.a;p.e<s;){if(r.K()==null)return null;++p.e}if(p.d>=p.b)return null
q=r.K()
if(q==null)return null;++p.d
return q},
L(){this.a.L()},
G(a){return B.a.P("  ",a)+"LimitNode(limit: "+this.b+", offset: "+this.c+")\n"+this.a.G(a+1)},
a6(){return this.G(0)}}
A.o3.prototype={
$1(a){return A.cw(B.a.V(a))},
$S:16}
A.dt.prototype={
gbP(){var s=this.y
s===$&&A.b()
return s},
bn(){var s,r,q,p,o,n=A.o(t.N,t.r)
for(s=this.e,r=s.b,q=r.length,s=s.a+".",p=0;p<r.length;r.length===q||(0,A.n)(r),++p){o=r[p]
n.k(0,s+o,new A.d())
n.k(0,o,new A.d())}return n},
N(){var s,r,q,p,o,n,m,l,k,j,i,h=this
h.a.N()
h.c.av()
h.Q=h.z=null
h.as.v(0)
s=h.at
B.b.v(s)
h.ax.v(0)
h.ay=null
if(h.r||h.w){r=h.b
q=r.a
p=q.ga5()
o=h.e
n=o.b
if(p!=null){m=p.a
l=r.fK(p.b,m,n.length,q.ax)}else l=r.fJ(n.length)
k=A.o(t.N,t.S)
for(r=o.a+".",j=0;j<n.length;++j){i=n[j]
k.k(0,r+i,j)
k.k(0,i,j)}while(l.p()){r=l.ax
r.toString
s.push(new A.aN(r,k))}}},
eT(a,b){var s,r,q,p
for(s=this.e.b,r=s.length,q=0;q<s.length;s.length===r||(0,A.n)(s),++q){p=s[q]
if(!J.az(a.h(0,p),b.h(0,p)))return!1}return!0},
K(){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2,b3=this,b4=null
for(s=!b3.f,r=b3.a,q=b3.w,p=b3.as,o=b3.c,n=t.n,m=b3.b,l=m.a,k=m.c+"/"+m.b+".db",j=b3.e,i=j.b,h=b3.at,g=A.z(h).i("aJ<1>"),f=g.i("F.E"),e=!b3.r;;){d=b3.ay
if(d!=null)if(d.p()){s=b3.ay
c=s.d
if(c==null)c=A.E(s).c.a(c)
s=t.N
r=t.r
b=A.o(s,r)
for(q=b3.x,p=q.length,a=0;a<q.length;q.length===p||(0,A.n)(q),++a)b.k(0,q[a],new A.d())
s=A.Z(b,s,r)
s.X(0,c)
return s}else return b4
a0=r.K()
if(a0==null){if(!e||q){a1=A.r(new A.aJ(h,new A.jE(b3),g),f)
b3.ay=new J.be(a1,a1.length,A.z(a1).i("be<1>"))
continue}return b4}a2=b3.bQ(a0)
if(a2 instanceof A.p)a3=a2.a
else a3=a2 instanceof A.j?a2.a:b4
if(a3!=null){if(p.F(a3)){c=p.h(0,a3)
if(c!=null){if(!e||q)for(s=h.length,a=0;a<h.length;h.length===s||(0,A.n)(h),++a){a4=h[a]
if(b3.eT(a4,c)){b3.ax.T(0,a4)
break}}a5=A.Z(a0,t.N,t.r)
a5.X(0,c)
return a5}if(!s||q){a6=b3.bn()
a5=A.Z(a0,t.N,t.r)
a5.X(0,a6)
return a5}continue}a7=o.bj(A.a([a3],n))
if(a7!=null){d=b3.Q
a8=a7.a
if(d!==a8){if(b3.z!=null){d.toString
l.u(k,d,!1)}b3.z=l.C(k,a8)
b3.Q=a8}d=b3.z
d.toString
a9=A.ab(d,a7.b)
if(a9!=null){b0=A.qO(m,a9,i.length)
if(b0!=null){s=t.N
r=t.r
c=A.o(s,r)
for(o=j.a+".",b1=0;b1<i.length;++b1)if(b1<b0.length){b2=i[b1]
c.k(0,o+b2,b0[b1])
c.k(0,b2,b0[b1])}p.k(0,a3,c)
if(!e||q)for(q=h.length,a=0;a<h.length;h.length===q||(0,A.n)(h),++a){a4=h[a]
if(b3.eT(a4,c)){b3.ax.T(0,a4)
break}}a5=A.Z(a0,s,r)
a5.X(0,c)
return a5}}}p.k(0,a3,b4)
if(!s||q){a6=b3.bn()
a5=A.Z(a0,t.N,t.r)
a5.X(0,a6)
return a5}}else if(!s||q){a6=b3.bn()
a5=A.Z(a0,t.N,t.r)
a5.X(0,a6)
return a5}}},
L(){var s,r,q=this
if(q.z!=null){s=q.b
r=q.Q
r.toString
s.a.u(s.c+"/"+s.b+".db",r,!1)
q.Q=q.z=null}q.as.v(0)
q.a.L()},
G(a){var s=this,r=B.a.P("  ",a),q=s.a.G(a+1),p=B.b.gW(s.c.b.split("/"))
return r+"IndexJoinNode(on: "+s.d+" = "+s.e.a+"."+A.T(p,".idx","")+")\n"+q},
a6(){return this.G(0)},
bQ(a){return this.gbP().$1(a)}}
A.jE.prototype={
$1(a){return!this.a.ax.E(0,a)},
$S:10}
A.dr.prototype={
gbP(){var s=this.w
s===$&&A.b()
return s},
N(){this.a.N()
var s=this.d
if(s!=null)s.av()},
K(){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2,b3,b4,b5,b6,b7,b8=this,b9=null
for(s=b8.b,r=s!=null,q=b8.c,p=q!=null,o=b8.d,n=o!=null,m=b8.a,l=b8.f,k=b8.r,j=k.b,i=k.a+".",h=t.N,g=t.r,f=t.bq,e=f.i("u.E"),d=t.f8,c=t.n;;){b=m.K()
if(b==null)return b9
a=b8.bQ(b)
if(n&&r){if(a instanceof A.p)a0=a.a
else a0=a instanceof A.j?a.a:b9
if(a0!=null){a1=o.bj(A.a([a0],c))
if(a1!=null){a2=s.a
a3=s.c+"/"+s.b+".db"
a4=a1.a
a5=A.ab(a2.C(a3,a4),a1.b)
if(a5!=null){a6=A.qO(s,a5,j.length)
if(a6!=null){a7=A.o(h,g)
for(a8=0;a8<j.length;++a8)if(a8<a6.length){a9=j[a8]
a7.k(0,i+a9,a6[a8])
a7.k(0,a9,a6[a8])}a2.u(a3,a4,!1)
b0=A.Z(b,h,g)
b0.X(0,a7)
return b0}}a2.u(a3,a4,!1)}}}else if(p){a2=k.dx
a2===$&&A.b()
b1=B.b.ac(a2,l.toLowerCase())
if(b1!==-1){b2=A.a([],d)
for(a8=0;a8<j.length;++a8){a2=q.cN(a8)
b2.push(new A.c8(a2.a(),a2.$ti.i("c8<1>")))}a2=b2.length
b3=a2!==0
for(b4=0;b4<b2.length;b2.length===a2||(0,A.n)(b2),++b4)if(!b2[b4].p())b3=!1
for(;;){if(!b3){b5=b9
break}b6=A.r(new A.h(b2,new A.jg(),f),e)
if(b1<b6.length)if(b6[b1].A(0,a)===0){b5=A.o(h,g)
for(a8=0;a8<j.length;++a8){a9=j[a8]
b5.k(0,i+a9,b6[a8])
b5.k(0,a9,b6[a8])}break}for(a2=b2.length,b4=0;b4<b2.length;b2.length===a2||(0,A.n)(b2),++b4)if(!b2[b4].p())b3=!1}if(b5!=null){b0=A.Z(b,h,g)
b0.X(0,b5)
return b0}}}else if(r){a2=k.dx
a2===$&&A.b()
b1=B.b.ac(a2,l.toLowerCase())
if(b1!==-1){b7=s.fI()
for(;;){if(!b7.p()){b5=b9
break}b6=b7.ax
if(b1<b6.length)if(b6[b1].A(0,a)===0){b5=A.o(h,g)
for(a8=0;a8<j.length;++a8)if(a8<b6.length){a9=j[a8]
b5.k(0,i+a9,b6[a8])
b5.k(0,a9,b6[a8])}break}}if(b5!=null){b0=A.Z(b,h,g)
b0.X(0,b5)
return b0}}}}},
L(){this.a.L()},
G(a){var s=this
return B.a.P("  ",a)+"GraphJoinNode(on: "+s.e+" -> "+s.r.a+"."+s.f+")\n"+s.a.G(a+1)},
a6(){return this.G(0)},
bQ(a){return this.gbP().$1(a)}}
A.jg.prototype={
$1(a){return a.gD()},
$S:88}
A.hc.prototype={
N(){var s,r,q=this,p=q.c
p.av()
s=q.r
r=s!=null?new A.jD(q,A.K(s)):null
q.w=p.cO(q.d,q.e,r)
q.x=0},
K(){var s,r,q,p,o,n,m,l,k,j,i,h,g,f=this,e=null,d=f.w
if(d==null||f.x>=d.length)return e
s=d[f.x++]
r=A.o(t.N,t.r)
d=f.b
q=f.a
p=q.c
if(d.d){o=d.a
for(d=d.b,q=q.a,n=s.c,m=s.d,p=p+"/"+o+".col_",o+=".",l=0;l<d.length;++l){k=p+l
if(n>=q.a_(k).a4())return f.K()
j=A.ab(q.C(k,n),m)
if(j!=null){i=A.bT(A.at(j,0,e),0,j.length)
h=d[l]
r.k(0,o+h,i)
r.k(0,h,i)}q.u(k,n,!1)}}else{o=q.a
q=p+"/"+q.b+".db"
p=s.c
j=A.ab(o.C(q,p),s.d)
if(j==null){o.u(q,p,!1)
return f.K()}g=A.a0(j,e,e)
for(n=d.b,d=d.a+".",l=0;l<n.length;++l)if(l<g.length){h=n[l]
r.k(0,d+h,g[l])
r.k(0,h,g[l])}o.u(q,p,!1)}return r},
L(){this.w=null},
G(a){var s=B.a.P("  ",a),r=this.r,q=r!=null?", filter: "+A.S(r):""
return s+"HnswScanNode(table: "+this.b.a+", limit: "+this.e+", maxDistance: null"+q+")"},
a6(){return this.G(0)}}
A.jD.prototype={
$2(a,a0){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d=A.o(t.N,t.r),c=this.a,b=c.b
c=c.a
g=c.c
if(b.d){f=b.a
for(s=0,b=b.b,c=c.a,g=g+"/"+f+".col_",f+=".";s<b.length;++s){r=g+A.D(s)
if(a>=c.a_(r).a4())return!1
q=c.C(r,a)
try{p=A.ab(q,a0)
if(p!=null){o=A.at(p,0,null)
n=A.bT(o,0,p.length)
m=b[s]
J.aY(d,f+A.D(m),n)
J.aY(d,m,n)}}finally{c.u(r,a,!1)}}}else{f=c.a
c=g+"/"+c.b+".db"
l=f.C(c,a)
try{k=A.ab(l,a0)
if(k==null)return!1
j=A.a0(k,null,null)
for(i=0,g=b.b,b=b.a+".";i<g.length;++i)if(i<J.O(j)){h=g[i]
J.aY(d,b+A.D(h),J.Y(j,i))
J.aY(d,h,J.Y(j,i))}}finally{f.u(c,a,!1)}}e=this.b.$1(d)
if(!(e instanceof A.p&&e.a===1))c=e instanceof A.j&&e.a>0
else c=!0
return c},
$S:41}
A.hi.prototype={
N(){var s,r,q=this,p=q.c
p.av()
s=q.r
r=s!=null?new A.l1(q,A.K(s)):null
q.w=p.cO(q.d,q.e,r)
q.x=0},
K(){var s,r,q,p,o,n,m,l,k,j,i,h,g,f=this,e=null,d=f.w
if(d==null||f.x>=d.length)return e
s=d[f.x++]
r=A.o(t.N,t.r)
d=f.b
q=f.a
p=q.c
if(d.d){o=d.a
for(d=d.b,q=q.a,n=s.b,m=s.c,p=p+"/"+o+".col_",o+=".",l=0;l<d.length;++l){k=p+l
if(n>=q.a_(k).a4())return f.K()
j=A.ab(q.C(k,n),m)
if(j!=null){i=A.bT(A.at(j,0,e),0,j.length)
h=d[l]
r.k(0,o+h,i)
r.k(0,h,i)}q.u(k,n,!1)}}else{o=q.a
q=p+"/"+q.b+".db"
p=s.b
j=A.ab(o.C(q,p),s.c)
if(j==null){o.u(q,p,!1)
return f.K()}g=A.a0(j,e,e)
for(n=d.b,d=d.a+".",l=0;l<n.length;++l)if(l<g.length){h=n[l]
r.k(0,d+h,g[l])
r.k(0,h,g[l])}o.u(q,p,!1)}return r},
L(){this.w=null},
G(a){var s=B.a.P("  ",a),r=this.r,q=r!=null?", filter: "+A.S(r):""
return s+"IvfFlatScanNode(table: "+this.b.a+", limit: "+this.e+", maxDistance: null"+q+")"},
a6(){return this.G(0)}}
A.l1.prototype={
$2(a,a0){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d=A.o(t.N,t.r),c=this.a,b=c.b
c=c.a
g=c.c
if(b.d){f=b.a
for(s=0,b=b.b,c=c.a,g=g+"/"+f+".col_",f+=".";s<b.length;++s){r=g+A.D(s)
if(a>=c.a_(r).a4())return!1
q=c.C(r,a)
try{p=A.ab(q,a0)
if(p!=null){o=A.at(p,0,null)
n=A.bT(o,0,p.length)
m=b[s]
J.aY(d,f+A.D(m),n)
J.aY(d,m,n)}}finally{c.u(r,a,!1)}}}else{f=c.a
c=g+"/"+c.b+".db"
l=f.C(c,a)
try{k=A.ab(l,a0)
if(k==null)return!1
j=A.a0(k,null,null)
for(i=0,g=b.b,b=b.a+".";i<g.length;++i)if(i<J.O(j)){h=g[i]
J.aY(d,b+A.D(h),J.Y(j,i))
J.aY(d,h,J.Y(j,i))}}finally{f.u(c,a,!1)}}e=this.b.$1(d)
if(!(e instanceof A.p&&e.a===1))c=e instanceof A.j&&e.a>0
else c=!0
return c},
$S:41}
A.bC.prototype={
aw(a,b){var s,r,q,p
if(b==null)return!1
if(!(b instanceof A.bC))return!1
s=this.a
r=s.length
q=b.a
if(r!==q.length)return!1
for(p=0;p<s.length;++p)if(!s[p].aw(0,q[p]))return!1
return!0},
gY(a){var s,r,q,p
for(s=this.a,r=s.length,q=17,p=0;p<s.length;s.length===r||(0,A.n)(s),++p)q=37*q+s[p].gY(0)
return q}}
A.hO.prototype={
fT(a,b){var s,r
for(s=this.b,r=0;r<s.length;++r)if(!s[r])this.f=r},
N(){var s,r,q=this,p=q.c=0
q.d.v(0)
q.e=null
for(s=q.a,r=s.length;p<s.length;s.length===r||(0,A.n)(s),++p)s[p].N()},
b0(a){if(a instanceof A.aN)return a.a
return J.fP(a.gaP())},
bN(a){var s
if(a instanceof A.aN){s=A.a9(a.a.length,"",!1,t.N)
a.b.a0(0,new A.na(s))
return s}return a.gZ().bc(0,new A.nb(),t.N).aO(0)},
K(){var s,r,q,p,o,n,m,l,k,j=this
for(s=j.a,r=j.d;q=j.c,q<s.length;){p=s[q].K()
if(p==null){++j.c
continue}o=j.b0(p)
if(j.e==null)j.e=j.bN(p)
q=j.f
if(q!==-1&&j.c<=q+1)if(!r.T(0,new A.bC(o)))continue
n=A.o(t.N,t.r)
for(m=0;s=j.e,m<s.length;++m){l=s[m]
k=m<o.length?o[m]:new A.d()
n.k(0,l,k)
n.k(0,B.b.gW(l.split(".")),k)}return n}return null},
L(){var s,r,q
for(s=this.a,r=s.length,q=0;q<s.length;s.length===r||(0,A.n)(s),++q)s[q].L()},
G(a){var s,r,q,p=B.a.P("  ",a)+"UnionNode(isAllFlags: "+A.D(this.b)+")\n"
for(s=this.a,r=a+1,q=0;q<s.length;++q){p+=s[q].G(r)
if(q<s.length-1)p+="\n"}return p.charCodeAt(0)==0?p:p},
a6(){return this.G(0)}}
A.na.prototype={
$2(a,b){var s,r=this.a
if(b<r.length){s=B.b.gW(a.split("."))
if(r[b].length===0||!B.a.E(a,"."))r[b]=s}},
$S:12}
A.nb.prototype={
$1(a){return B.b.gW(a.split("."))},
$S:7}
A.hg.prototype={
N(){var s,r,q,p=this
for(s=p.a,r=s.length,q=0;q<s.length;s.length===r||(0,A.n)(s),++q)s[q].N()
p.b.v(0)
p.d=p.c=null
p.e=!1},
b0(a){if(a instanceof A.aN)return a.a
return J.fP(a.gaP())},
bN(a){var s
if(a instanceof A.aN){s=A.a9(a.a.length,"",!1,t.N)
a.b.a0(0,new A.kU(s))
return s}return a.gZ().aO(0)},
da(){var s,r,q,p,o,n,m=this
if(m.e)return
m.e=!0
m.c=A.a([],t.bA)
for(s=m.a,r=t.Y,q=1;q<s.length;++q){p=A.aD(r)
o=s[q]
for(;;){n=o.K()
if(n==null)break
p.T(0,new A.bC(m.b0(n)))}m.c.push(p)}},
K(){var s,r,q,p,o,n,m,l,k,j,i,h,g=this
g.da()
for(s=g.b,r=g.a;;){q=r[0].K()
if(q==null)return null
p=g.b0(q)
if(g.d==null)g.d=g.bN(q)
o=new A.bC(p)
m=g.c
l=m.length
k=0
for(;;){if(!(k<m.length)){n=!0
break}if(!m[k].E(0,o)){n=!1
break}m.length===l||(0,A.n)(m);++k}if(!n)continue
if(!s.T(0,o))continue
j=A.o(t.N,t.r)
for(i=0;s=g.d,i<s.length;++i){h=s[i]
j.k(0,h,i<p.length?p[i]:new A.d())}return j}},
L(){var s,r,q
for(s=this.a,r=s.length,q=0;q<s.length;s.length===r||(0,A.n)(s),++q)s[q].L()},
G(a){var s,r,q,p=B.a.P("  ",a)+"IntersectNode\n"
for(s=this.a,r=a+1,q=0;q<s.length;++q){p+=s[q].G(r)
if(q<s.length-1)p+="\n"}return p.charCodeAt(0)==0?p:p},
a6(){return this.G(0)}}
A.kU.prototype={
$2(a,b){var s,r=this.a
if(b<r.length){s=r[b]
if(s.length===0||B.a.E(s,"."))r[b]=a}},
$S:12}
A.h5.prototype={
N(){var s,r,q,p=this
for(s=p.a,r=s.length,q=0;q<s.length;s.length===r||(0,A.n)(s),++q)s[q].N()
p.b.v(0)
p.d=p.c=null
p.e=!1},
b0(a){if(a instanceof A.aN)return a.a
return J.fP(a.gaP())},
bN(a){var s
if(a instanceof A.aN){s=A.a9(a.a.length,"",!1,t.N)
a.b.a0(0,new A.j1(s))
return s}return a.gZ().aO(0)},
da(){var s,r,q,p,o,n,m=this
if(m.e)return
m.e=!0
m.c=A.a([],t.bA)
for(s=m.a,r=t.Y,q=1;q<s.length;++q){p=A.aD(r)
o=s[q]
for(;;){n=o.K()
if(n==null)break
p.T(0,new A.bC(m.b0(n)))}m.c.push(p)}},
K(){var s,r,q,p,o,n,m,l,k,j,i,h,g=this
g.da()
for(s=g.b,r=g.a;;){q=r[0].K()
if(q==null)return null
p=g.b0(q)
if(g.d==null)g.d=g.bN(q)
o=new A.bC(p)
m=g.c
l=m.length
k=0
for(;;){if(!(k<m.length)){n=!1
break}if(m[k].E(0,o)){n=!0
break}m.length===l||(0,A.n)(m);++k}if(n)continue
if(!s.T(0,o))continue
j=A.o(t.N,t.r)
for(i=0;s=g.d,i<s.length;++i){h=s[i]
j.k(0,h,i<p.length?p[i]:new A.d())}return j}},
L(){var s,r,q
for(s=this.a,r=s.length,q=0;q<s.length;s.length===r||(0,A.n)(s),++q)s[q].L()},
G(a){var s,r,q,p=B.a.P("  ",a)+"ExceptNode\n"
for(s=this.a,r=a+1,q=0;q<s.length;++q){p+=s[q].G(r)
if(q<s.length-1)p+="\n"}return p.charCodeAt(0)==0?p:p},
a6(){return this.G(0)}}
A.j1.prototype={
$2(a,b){var s,r=this.a
if(b<r.length){s=r[b]
if(s.length===0||B.a.E(s,"."))r[b]=a}},
$S:12}
A.h1.prototype={
N(){this.a.N()
this.b.v(0)},
b0(a){if(a instanceof A.aN)return a.a
return J.fP(a.gaP())},
K(){var s,r,q
for(s=this.b,r=this.a;;){q=r.K()
if(q==null)return null
if(!s.T(0,new A.bC(this.b0(q))))continue
return q}},
L(){this.a.L()
this.b.v(0)},
G(a){return B.a.P("  ",a)+"DistinctNode\n"+this.a.G(a+1)},
a6(){return this.G(0)}}
A.mp.prototype={
hE(a,b){var s=A.o(t.N,t.k),r=a.b,q=0
for(;;){if(!(q<r.length&&q<b.length))break
s.k(0,r[q].toLowerCase(),b[q]);++q}return new A.mq(s).$1(a.c)},
bR(a,b){var s,r,q,p=B.a.V(a),o=new A.ms()
while(o.$1(p))p=B.a.V(B.a.O(p,1,p.length-1))
s=A.aI("\\s+",!0)
r=A.T(p,s,"").toLowerCase()
q=b.toLowerCase()+"."
if(B.a.U(r,q))return B.a.az(r,q.length)
return r},
d4(a){var s,r=this.a.c.h(0,a.b.toLowerCase().toLowerCase())
if(r==null)return 1
s=a.c
return B.b.cr(A.a(s.split(","),t.s),new A.mr(r))?s.split(",").length:1},
is(a){var s=this
if(a instanceof A.cS)return s.j2(a)
if(a instanceof A.du)return s.j1(a)
if(a instanceof A.dm)return s.j_(a)
if(a instanceof A.aS)return s.aM(a)
throw A.c(A.q("Unsupported statement type for query planner: "+A.ip(a).l(0)))},
j2(a){var s=a.a,r=A.z(s).i("h<1,P>"),q=A.r(new A.h(s,new A.mF(this),r),r.i("u.E"))
return A.qu(q,a.b)},
j1(a){var s=a.a,r=A.z(s).i("h<1,P>"),q=A.r(new A.h(s,new A.mz(this),r),r.i("u.E"))
return new A.hg(q,A.aD(t.Y))},
j_(a){var s=a.a,r=A.z(s).i("h<1,P>"),q=A.r(new A.h(s,new A.mw(this),r),r.i("u.E"))
return new A.h5(q,A.aD(t.Y))},
aM(m3){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2,b3,b4,b5,b6,b7,b8,b9,c0,c1,c2,c3,c4,c5,c6,c7,c8,c9,d0,d1,d2,d3,d4,d5,d6,d7,d8,d9,e0,e1,e2,e3,e4,e5,e6,e7,e8,e9,f0,f1,f2,f3,f4,f5,f6,f7,f8,f9,g0,g1,g2,g3,g4,g5,g6,g7,g8,g9,h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,i0,i1,i2,i3,i4,i5,i6,i7,i8,i9,j0,j1,j2,j3,j4,j5,j6,j7,j8,j9,k0,k1,k2,k3,k4,k5,k6,k7,k8,k9,l0,l1,l2,l3,l4,l5,l6,l7,l8=this,l9=null,m0="' does not exist in catalog.",m1="euclidean",m2="' does not exist."
m3=m3
if(m3 instanceof A.di)if(m3.CW){c=m3.ay
b=new A.aB(c,A.E(c).i("aB<1>")).gH(0)
c=m3.ay.h(0,b)
c.toString
if(c instanceof A.cS){c=c.a
a=B.b.gH(c)
a0=B.b.gW(c)}else{if(!(c instanceof A.aS))return l8.aM(l8.ci(m3.ch,m3.ay))
a0=c
a=a0}return l8.i5(m3,a,a0,b)}else return l8.aM(l8.ci(m3.ch,m3.ay))
m3=l8.ia(m3)
a1=A.qv()
m3.toString
a2=!1
a3=!1
a4=!1
if(m3.c!=null){c=m3.c
c.toString
a5=l8.aM(c)
c=t.s
s=A.a([],c)
r=A.a([],t.d)
for(a6=m3.c.a,a7=a6.length,a8=0;a8<a6.length;a6.length===a7||(0,A.n)(a6),++a8){a9=a6[a8]
b0=a9.b
if(b0!=null)s.push(b0)
else{b0=a9.a
if(b0 instanceof A.H)s.push(B.b.gW(b0.b))
else s.push(A.S(b0))}r.push(B.t)}b1=m3.e
b2=A.bJ(l9,l9,l9,s,l9,l9,l9,l9,r,l9,l9,l9,!1,!1,b1==null?"subquery":b1,l9,l9,l9,l9,l9,l9)
a1.b=new A.dR(a5,m3.e)
b3=m3.a
if(b3.length===1){a6=b3[0].a
a6=a6 instanceof A.H&&B.b.gH(a6.b)==="*"}else a6=!1
if(a6){h=A.a([],t.u)
for(a6=b2.b,a7=a6.length,a8=0;a8<a6.length;a6.length===a7||(0,A.n)(a6),++a8)h.push(new A.ai(new A.H(A.a([a6[a8]],c)),l9))
for(a6=m3.f,a7=a6.length,b0=l8.a.c,a8=0;a8<a6.length;a6.length===a7||(0,A.n)(a6),++a8){b4=b0.h(0,a6[a8].a.toLowerCase().toLowerCase())
if(b4!=null)for(b5=b4.b,b6=b5.length,b7=b4.a,b8=0;b8<b5.length;b5.length===b6||(0,A.n)(b5),++b8)h.push(new A.ai(new A.H(A.a([b7,b5[b8]],c)),l9))}b3=h}}else if(m3.d!=null){c=t.s
s=A.a([],c)
r=A.a([],t.d)
try{a6=m3.d
a6.toString
q=A.bM(a6,A.o(t.N,t.r))
p=[]
if(q instanceof A.aP)p=q.a
else if(q instanceof A.M&&t.j.b(q.ga2()))p=t.j.a(q.ga2())
else if(q instanceof A.m)try{o=B.o.ag(q.a)
if(t.j.b(o))p=o}catch(b9){}if(J.pG(p)){n=J.e3(p)
a6=t.f
if(a6.b(n))for(a6=n.gZ(),a6=a6.gJ(a6);a6.p();){m=a6.gD()
J.ae(s,J.x(m))
J.ae(r,B.t)}else{a7=t.j
if(a7.b(n))for(l=0;l<J.O(n);++l){J.ae(s,"col"+A.D(l))
J.ae(r,B.t)}else if(n instanceof A.M&&a6.b(n.ga2())){k=a6.a(n.ga2())
for(a6=k.gZ(),a6=a6.gJ(a6);a6.p();){j=a6.gD()
J.ae(s,J.x(j))
J.ae(r,B.t)}}else if(n instanceof A.aP)for(i=0;i<n.a.length;++i){J.ae(s,"col"+A.D(i))
J.ae(r,n.a[i].gae())}else if(n instanceof A.M&&a7.b(n.ga2())){h=a7.a(n.ga2())
for(g=0;g<J.O(h);++g){J.ae(s,"col"+A.D(g))
J.ae(r,B.t)}}else{J.ae(s,"value")
a6=n instanceof A.k?n.gae():B.t
J.ae(r,a6)}}}}catch(b9){}if(J.O(s)===0){J.ae(s,"value")
J.ae(r,B.t)}c0=m3.e
if(c0==null)c0=m3.d.b
b2=A.bJ(l9,l9,l9,s,l9,l9,l9,l9,r,l9,l9,l9,!1,!1,c0,l9,l9,l9,l9,l9,l9)
a6=m3.d
a6.toString
a1.b=new A.hb(a6,m3.e)
b3=m3.a
if(b3.length===1){a6=b3[0].a
a6=a6 instanceof A.H&&B.b.gH(a6.b)==="*"}else a6=!1
if(a6){h=A.a([],t.u)
for(a6=b2.b,a7=a6.length,a8=0;a8<a6.length;a6.length===a7||(0,A.n)(a6),++a8)h.push(new A.ai(new A.H(A.a([a6[a8]],c)),l9))
a6=m3.f
if((a6.length!==0?B.b.gH(a6):l9)!=null){a6=m3.f
b4=l8.a.c.h(0,(a6.length!==0?B.b.gH(a6):l9).a.toLowerCase().toLowerCase())
if(b4!=null)for(a6=b4.b,a7=a6.length,b0=b4.a,a8=0;a8<a6.length;a6.length===a7||(0,A.n)(a6),++a8)h.push(new A.ai(new A.H(A.a([b0,a6[a8]],c)),l9))}b3=h}}else{c1=m3.b.toLowerCase()
c=l8.a
a6=c.c
c2=a6.h(0,c1.toLowerCase())
if(c2==null)if(c1.length===0){s=A.a([],t.s)
r=A.a([],t.d)
for(a7=m3.a,b0=a7.length,a8=0;a8<a7.length;a7.length===b0||(0,A.n)(a7),++a8){a9=a7[a8]
b5=a9.b
if(b5!=null)s.push(b5)
else{b5=a9.a
if(b5 instanceof A.H)s.push(B.b.gW(b5.b))
else s.push(A.S(b5))}r.push(B.t)}if(s.length===0){s.push("dual")
r.push(B.t)}b2=A.bJ(l9,l9,l9,s,l9,l9,l9,l9,r,l9,l9,l9,!1,!1,"dual",l9,l9,l9,l9,l9,l9)
a1.b=new A.dA(A.a([A.o(t.N,t.r)],t.b))}else throw A.c(A.q("Table '"+c1+m0))
else b2=c2
b3=m3.a
if(b3.length===1){a7=b3[0].a
a7=a7 instanceof A.H&&B.b.gH(a7.b)==="*"}else a7=!1
if(a7){h=A.a([],t.u)
for(a7=b2.b,b0=a7.length,b5=t.s,a8=0;a8<a7.length;a7.length===b0||(0,A.n)(a7),++a8)h.push(new A.ai(new A.H(A.a([a7[a8]],b5)),l9))
for(a7=m3.f,b0=a7.length,a8=0;a8<a7.length;a7.length===b0||(0,A.n)(a7),++a8){b4=a6.h(0,a7[a8].a.toLowerCase().toLowerCase())
if(b4!=null)for(b6=b4.b,b7=b6.length,c3=b4.a,b8=0;b8<b6.length;b6.length===b7||(0,A.n)(b6),++b8)h.push(new A.ai(new A.H(A.a([c3,b6[b8]],b5)),l9))}b3=h}a6=b2.db
if(a6.length!==0){c4=A.a([],t.bL)
for(c=a6.length,a7=t.s,b0=t.u,a8=0;a8<a6.length;a6.length===c||(0,A.n)(a6),++a8){c5=a6[a8]
b5=A.a([new A.ai(new A.H(A.a(["*"],a7)),l9)],b0)
c6=l8.aM(new A.aS(b5,c5,l9,l9,l9,B.b9,l9,l9,l9,l9,l9,l9,l9,!1,l9))
c7=m3.e
c4.push(new A.dR(c6,c7==null?m3.b:c7))}c=c4.length
if(c===0)a1.b=new A.dA(A.a([],t.b))
else if(c===1)a1.b=B.b.gH(c4)
else a1.b=A.qu(c4,A.a9(c-1,!0,!1,t.y))}else{if(m3.y!=null){c8=m3.y.a
if(c8 instanceof A.af&&c8.b.toLowerCase()==="vector_distance")c9=c8
else{c9=l9
if(c8 instanceof A.H){d0=B.b.gW(c8.b).toLowerCase()
for(a6=m3.a,a7=a6.length,b0=t.du,a8=0;a8<a7;++a8){a9=a6[a8]
b5=a9.b
if((b5==null?l9:b5.toLowerCase())===d0&&a9.a instanceof A.af){d1=b0.a(a9.a)
if(d1.b.toLowerCase()==="vector_distance"){c9=d1
break}}}}}if(c9!=null){a6=c9.c.length
a6=a6===2||a6===3}else a6=!1
if(a6){a6=c9.c
d2=a6[0]
if(d2 instanceof A.H){d3=c.b5(c1,B.b.gW(d2.b).toLowerCase())
if(d3!=null){a7=d3.d
a7=a7==="hnsw"||a7==="ivf_flat"}else a7=!1
if(a7){a7=t.N
b0=t.r
f=A.bM(a6[1],A.o(a7,b0))
if(f instanceof A.m){e=B.a.V(f.a)
if(J.rV(e,"[")&&J.rR(e,"]"))try{b5=t.dh
p=A.r(new A.h(A.a(J.rW(e,1,J.O(e)-1).split(","),t.s),new A.mA(),b5),b5.i("u.E"))
d=p
f=new A.a5(d)}catch(b9){}}if(f instanceof A.a5){if(a6.length===3){d4=A.bM(a6[2],A.o(a7,b0))
d5=d4 instanceof A.m?d4.a.toLowerCase():m1}else d5=m1
d6=m3.z
if(d6==null)d6=10
c=l8.c
d7=A.aO(l8.b,c,b2.a)
d8=d3.d==="ivf_flat"
a6=d3.a
a7=d8?"ivf_flat":"hnsw"
d9=c+"/"+a6.toLowerCase()+"."+a7
e0=d8?new A.hi(d7,b2,A.q0(!1,d9,d5),f,d6,m3.r):new A.hc(d7,b2,A.oN(!1,d9,d5),f,d6,m3.r)
c=b2.Q
if(c.length!==0){e1=B.b.gH(c).b
for(a6=c.length,l=1;l<a6;++l)e1=new A.a1("OR",e1,c[l].b)
e0=A.er(e0,e1)}b3=m3.a
if(b3.length===1){c=b3[0].a
c=c instanceof A.H&&B.b.gH(c.b)==="*"}else c=!1
if(c){h=A.a([],t.u)
for(c=b2.b,a6=c.length,a7=t.s,a8=0;a8<c.length;c.length===a6||(0,A.n)(c),++a8)h.push(new A.ai(new A.H(A.a([c[a8]],a7)),l9))
b3=h}return A.hD(e0,b3)}}}}}a6=b2.d
e2=l9
e3=l9
e4=l9
if(!a6&&m3.r!=null){a7=m3.r
a7.toString
e5=A.ph(a7)
if(e5!=null){a1.b=new A.ha(c1,e5.b,e5.c,l8.c,l8.b,c)
a3=!0}else{for(a7=J.as(c.bf(c1)),b0=t.s,b5=t.e,b6=b5.i("u.E"),e6=e4,e7=e3,e8=e2,e9=-1;a7.p();){f0=a7.gD()
f1=A.r(new A.h(A.a(f0.c.split(","),b0),new A.mB(),b5),b6)
if(f1.length===0)continue
b7=m3.r
b7.toString
f2=l8.el(b7,c1,f1)
if(f2!=null){f3=f2[0]
f4=f3.length
if(f4>e9){e6=f2[1]
e9=f4
e7=f3
e8=f0}}}if(e8!=null){f5=c.f.h(0,c1.toLowerCase())
c=f5==null
f6=c?l9:f5.a
if(f6==null)f6=1000
a7=e7!=null
b6=!0
if(a7)if(e6!=null){b6=e7.length
b6=b6===0||b6!==e6.length}f7=!1
if(!b6){b6=e7.length
l=0
for(;;){if(!(l<b6)){f7=!0
break}if(e7[l]!==e6[l])break;++l}}if(f7){f8=c?l9:f5.b.h(0,B.a.V(B.b.gH(e8.c.split(","))).toLowerCase())
f9=f8==null?l9:f8.c
if(f9==null)f9=10
g0=f9>0?1/f9:0.01}else{b6=B.a.V(B.b.gH(e8.c.split(",")))
f8=c?l9:f5.b.h(0,b6.toLowerCase())
c=f8==null
g1=c?l9:f8.a
g2=c?l9:f8.b
g3=a7&&e7.length!==0?e7[0]:l9
g4=e6!=null&&e6.length!==0?e6[0]:l9
if(typeof g1=="number"&&typeof g2=="number"&&g2>g1){g5=g3==null?g1:g3
g0=((g4==null?g2:g4)-g5)/(g2-g1)}else g0=0.1}g0=B.h.du(g0,0,1)
a3=f7||g0*f6<0.4*f6
if(a3){g6=A.aD(t.N)
c=m3.r
c.toString
l8.af(c,g6)
g7=new A.h(A.a(e8.c.split(","),b0),new A.mC(),b5).ja(0)
g8=!1
if(m3.r instanceof A.a1){g9=t.el.a(m3.r)
if(g9.b==="="&&g9.c instanceof A.H)g8=g7.E(0,B.a.V(B.b.gW(t.w.a(g9.c).b).toLowerCase()))}if(!g8)a4=!0
else for(c=A.i7(g6,g6.r,g6.$ti.c),a7=c.$ti.c;c.p();){b0=c.d
if(b0==null)b0=a7.a(b0)
if(!g7.E(0,B.b.gW(B.a.V(b0.toLowerCase()).split(".")))){a4=!0
break}}}e4=e6
e3=e7
e2=e8}}}if(a6)a1.b=A.pP(new A.bQ(l8.b,b2.a,l8.c),b2,l8.eq(m3,b2))
else if(a3&&e2!=null){c=l8.c
a6=l8.b
h0=A.fU(a6,c+"/"+e2.a.toLowerCase()+".idx",l8.d4(e2))
d7=A.aO(a6,c,b2.a)
h1=a3&&!a4
a1.b=A.tk(e4,h0,e3,l8.er(m3,b2,h1),b2,d7)}else if(!a3&&m3.c==null&&m3.d==null&&m3.b.length!==0){c=l8.b
a6=b2.a
d7=A.aO(c,l8.c,a6)
if(b2.at){c=b2.b
h2=c.length
h3=J.dv(h2,t.bv)
for(a7=b2.c,l=0;l<h2;++l)h3[l]=new A.b_(c[l],a7[l],!1,!1,l9,l9,!1,l9,l9,l9)
c=b2.ax
c.toString
a7=b2.ay
a7.toString
a1.b=new A.h7(new A.dc(a6,h3,c,a7))}else{a6=d7.c+"/"+d7.b+".db"
h4=c.a_(a6).a4()
h5=l8.eq(m3,b2)
if(h4>50)if(c.gab()==null){a7=m3.f
a7=(a7.length!==0?B.b.gH(a7):l9)==null&&m3.as==null
a2=a7}if(a2){c=c.f
a7=m3.r
b0=m3.w==null&&!l8.bO(m3.a)?b3:l9
b5=$.rp()
b6=m3.w
a1.b=new A.dG(a6,b2,c,a7,b0,h4,b5,b6,m3.w!=null||l8.bO(m3.a)?b3:l9)}else{if(m3.ax!=null){q=A.bM(m3.ax.b,A.o(t.N,t.r))
if(q instanceof A.p)h6=q.a
else h6=q instanceof A.j?B.h.bd(q.a):A.a4(q.l(0),l9)}else h6=l9
a1.b=A.qk(d7,b2,h5,h6)}}}}}c=b2.Q
if(c.length!==0){e1=B.b.gH(c).b
for(a6=c.length,l=1;l<a6;++l)e1=new A.a1("OR",e1,c[l].b)
a1.b=A.er(a1.eP(),e1)}h7=a1.eP()
c=t.s
h8=A.a([],c)
for(a6=b2.b,a7=a6.length,b0=b2.a+".",a8=0;a8<a6.length;a6.length===a7||(0,A.n)(a6),++a8){h9=a6[a8]
h8.push(h9)
h8.push(b0+h9)}a6=m3.f.length
if(a6>1)B.b.aq(m3.f,new A.mD(l8))
for(a6=m3.f,a7=a6.length,b0=t.N,b5=t.c,b6=t.b,b7=t.b_,c3=l8.a,i0=l8.b,i1=l8.c,i2=c3.c,i3=t.w,i4=t.d,i5=i1+"/",i6=t.i,i7=t.fY,a8=0;a8<a6.length;a6.length===a7||(0,A.n)(a6),++a8){i8=a6[a8]
i9=i8.b
if(i9!=null){a5=l8.aM(i9)
s=A.a([],c)
r=A.a([],i4)
for(i9=i9.a,j0=i9.length,b8=0;b8<i9.length;i9.length===j0||(0,A.n)(i9),++b8){a9=i9[b8]
j1=a9.b
if(j1!=null)s.push(j1)
else{j1=a9.a
if(j1 instanceof A.H)s.push(B.b.gW(j1.b))
else s.push(A.S(j1))}r.push(B.t)}j2=i8.c
j3=j2==null?"join_subquery":j2
b4=A.bJ(l9,l9,l9,s,l9,l9,l9,l9,r,l9,l9,l9,!1,!1,j3,l9,l9,l9,l9,l9,l9)
j4=new A.dR(a5,j2)
j5=j3}else{j5=i8.a.toLowerCase()
j6=i2.h(0,j5.toLowerCase())
if(j6==null)throw A.c(A.q("Join table '"+j5+m2))
i9=j6.d
j0=j6.a
if(i9)j4=A.pP(new A.bQ(i0,j0,i1),j6,l8.es(m3,i8,j6))
else{d7=new A.ck(i0,j0,i1)
d7.d=new A.fg(i0,i1,j0)
j4=A.qk(d7,j6,l8.es(m3,i8,j6),l9)}b4=j6}i9=b4.Q
if(i9.length!==0){j7=B.b.gH(i9).b
for(j0=i9.length,l=1;l<j0;++l)j7=new A.a1("OR",j7,i9[l].b)
j4=new A.cE(j4,j7)
j4.c=A.K(j7)}j8=i8.d
j9=""
k0=""
if(j8 instanceof A.a1&&j8.b==="="){i9=j8.c
if(i9 instanceof A.H&&j8.d instanceof A.H){k1=i3.a(j8.d)
k2=j5.toLowerCase()
j0=i8.c
k3=j0==null?l9:j0.toLowerCase()
i9=i9.b
k4=i9[0].toLowerCase()
j0=k1.b
k5=j0[0].toLowerCase()
if(k5!==k2)j1=k3!=null&&k5===k3
else j1=!0
if(j1){j9=B.b.R(B.b.ad(i9,1),".")
k0=B.b.R(B.b.ad(j0,1),".")}else{if(k4!==k2)j1=k3!=null&&k4===k3
else j1=!0
if(j1){j9=B.b.R(B.b.ad(j0,1),".")
k0=B.b.R(B.b.ad(i9,1),".")}}}}if(j9.length===0||k0.length===0){h7=new A.hs(h7,j4,j8,i8.e,i8.f,i8.r,A.a6(h8,!0,b0),b4,A.a([],b6),A.aD(b7))
h7.x=A.K(j8)}else{d3=c3.b5(j5,k0)
k6=d3==null?l9:d3.a.toLowerCase()
d9=k6!=null?i5+k6+".idx":l9
k7=!b4.d&&d9!=null
i9=i8.e
j0=i8.f
j1=i8.r
if(k7){k8=b4.a
k9=new A.ck(i0,k8,i1)
k9.d=new A.fg(i0,i1,k8)
d3.toString
h7=new A.dt(h7,k9,A.fU(i0,d9,l8.d4(d3)),j9,b4,i9,j0,j1,A.a6(h8,!0,b0),A.o(i6,i7),A.a([],b6),A.aD(b7))
h7.y=A.K(new A.H(A.a([j9],c)))}else{h7=new A.ds(h7,j4,j9,k0,i9,j0,j1,A.a6(h8,!0,b0),b4,A.o(b0,b5),A.a([],b6),A.aD(b7))
h7.y=A.K(new A.H(A.a([j9],c)))
h7.z=A.K(new A.H(A.a([k0],c)))}}for(i9=b4.b,j0=i9.length,j1=b4.a+".",b8=0;b8<i9.length;i9.length===j0||(0,A.n)(i9),++b8){h9=i9[b8]
h8.push(h9)
h8.push(j1+h9)}}if(m3.as!=null){l0=m3.as.toLowerCase()
l1=c3.d.h(0,l0.toLowerCase())
if(l1==null)throw A.c(A.q("Relationship '"+l0+m0))
l2=l1.c.toLowerCase()
l3=i2.h(0,l2.toLowerCase())
if(l3==null)throw A.c(A.q("Target table '"+l2+"' of relationship '"+l0+m2))
a6=l3.d
a7=l3.a
if(a6){l4=new A.bQ(i0,a7,i1)
l5=l9}else{l5=A.aO(i0,i1,a7)
l4=l9}a7=l1.e
d3=c3.b5(l2,a7)
k6=d3==null?l9:d3.a.toLowerCase()
d9=k6!=null?i5+k6+".idx":l9
if(!a6&&d9!=null){d3.toString
l6=A.fU(i0,d9,l8.d4(d3))}else l6=l9
a6=l1.d
h7=new A.dr(h7,l5,l4,l6,a6,a7,l3)
h7.w=A.K(new A.H(A.a([a6],c)))}if(m3.r!=null)c=(!a3||a4)&&!a2
else c=!1
if(c){c=m3.r
c.toString
h7=A.er(h7,c)}l7=l8.hI(b3)
if(l7.length!==0){if(m3.w!=null&&!a2){c=m3.w
c.toString
h7=new A.bW(h7,c,b3,m3.x)}else if(l8.bO(b3)&&!a2)h7=new A.bW(h7,new A.ag(1),b3,m3.x)
for(c=l7.length,a8=0;a8<c;++a8)h7=new A.hU(h7,l7[a8])
if(m3.w==null&&!l8.bO(b3)&&!a2)h7=A.hD(h7,b3)}else if(m3.w!=null&&!a2){c=m3.w
c.toString
h7=new A.bW(h7,c,b3,m3.x)}else if(l8.bO(b3)&&!a2)h7=new A.bW(h7,new A.ag(1),b3,m3.x)
else if(!a2)h7=A.hD(h7,b3)
if(a2&&m3.x!=null){c=m3.x
c.toString
h7=A.er(h7,c)}if(m3.at)h7=new A.h1(h7,A.aD(t.Y))
if(m3.y!=null)h7=A.qn(h7,m3.y.a,m3.y.b)
if(m3.z!=null){c=m3.z
c.toString
a6=m3.Q
h7=new A.cK(h7,c,a6==null?0:a6)}return h7},
er(a,a0,a1){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c=this,b=a.a
if(b.length===1){s=b[0].a
s=s instanceof A.H&&B.b.gH(s.b)==="*"}else s=!1
if(s){r=a0.b.length
q=J.dv(r,t.S)
for(p=0;p<r;++p)q[p]=p
return q}o=A.aD(t.N)
for(s=b.length,n=0;n<b.length;b.length===s||(0,A.n)(b),++n)c.af(b[n].a,o)
b=a.r
if(b!=null&&!a1)c.af(b,o)
for(b=a.f,s=b.length,n=0;n<b.length;b.length===s||(0,A.n)(b),++n)c.af(b[n].d,o)
b=a.y
if(b!=null)c.af(b.a,o)
b=a.as
if(b!=null){m=c.a.d.h(0,b.toLowerCase().toLowerCase())
if(m!=null&&m.b.toLowerCase()===a0.a.toLowerCase())o.T(0,m.d)}b=a.e
l=b==null?null:b.toLowerCase()
k=A.aD(t.S)
for(b=A.i7(o,o.r,o.$ti.c),s=a0.b,j=a0.a,i=l!=null,h=b.$ti.c;b.p();){g=b.d
if(g==null)g=h.a(g)
f=g.toLowerCase()
for(p=0;p<s.length;++p){e=s[p].toLowerCase()
g=!0
if(f!==e)if(f!==j.toLowerCase()+"."+e){if(i){g=l+"."+e
g=f===g||B.a.U(f,g+".")}else g=!1
g=g||B.a.U(f,e+".")||B.a.U(f,j.toLowerCase()+"."+e+".")}if(g)k.T(0,p)}}if(k.a===0){if(a1)return A.a([],t.t)
return A.a([0],t.t)}d=A.r(k,k.$ti.c)
B.b.dS(d)
return d},
eq(a,b){return this.er(a,b,!1)},
es(a,b,c){var s,r,q,p,o,n,m,l,k,j,i,h,g=this,f=A.aD(t.N)
g.af(b.d,f)
for(s=a.a,r=s.length,q=0;q<s.length;s.length===r||(0,A.n)(s),++q)g.af(s[q].a,f)
s=a.r
if(s!=null)g.af(s,f)
s=a.w
if(s!=null)g.af(s,f)
s=a.y
if(s!=null)g.af(s.a,f)
s=a.x
if(s!=null)g.af(s,f)
s=b.c
p=s==null?null:s.toLowerCase()
o=A.aD(t.S)
for(s=A.i7(f,f.r,f.$ti.c),r=c.b,n=c.a,m=p!=null,l=s.$ti.c;s.p();){k=s.d
if(k==null)k=l.a(k)
j=k.toLowerCase()
for(i=0;i<r.length;++i){h=r[i].toLowerCase()
k=!0
if(j!==h)if(j!==n.toLowerCase()+"."+h){if(m){k=p+"."+h
k=j===k||B.a.U(j,k+".")}else k=!1
k=k||B.a.U(j,h+".")||B.a.U(j,n.toLowerCase()+"."+h+".")}if(k)o.T(0,i)}}if(o.a===0)return A.a([0],t.t)
s=A.r(o,o.$ti.c)
B.b.dS(s)
return s},
af(a,b){var s,r,q,p,o=this
if(a instanceof A.H)b.T(0,B.b.R(a.b,"."))
else if(a instanceof A.ba)o.af(a.b,b)
else if(a instanceof A.a1){o.af(a.c,b)
o.af(a.d,b)}else if(a instanceof A.af)for(s=a.c,r=s.length,q=0;q<s.length;s.length===r||(0,A.n)(s),++q)o.af(s[q],b)
else if(a instanceof A.bK){for(s=a.d,r=s.length,q=0;q<s.length;s.length===r||(0,A.n)(s),++q)o.af(s[q],b)
s=a.e
if(s!=null)o.af(s.a,b)}else if(a instanceof A.d9){for(s=a.b,r=s.length,q=0;q<s.length;s.length===r||(0,A.n)(s),++q){p=s[q]
o.af(p.a,b)
o.af(p.b,b)}s=a.c
if(s!=null)o.af(s,b)}},
bO(a){var s,r
for(s=a.length,r=0;r<s;++r)if(this.cc(a[r].a))return!0
return!1},
cc(a){var s
if(a instanceof A.af){s=a.b.toLowerCase()
if(s==="count"||s==="sum"||s==="avg"||s==="min"||s==="max")return!0}if(a instanceof A.ba)return this.cc(a.b)
if(a instanceof A.a1)return this.cc(a.c)||this.cc(a.d)
return!1},
io(a,b){var s,r,q,p,o
if(a instanceof A.a1)if(a.b.toUpperCase()==="AND"){s=this.dn(a.c,b)
r=this.dn(a.d,b)
if(s!=null&&r!=null&&s.a===r.a){q=s.a
p=s.b
if(p==null)p=r.b
o=s.c
return new A.bj(q,p,o==null?r.c:o)}}else return this.dn(a,b)
return null},
cf(a){if(a instanceof A.ag)return a.b
a instanceof A.aR
return null},
dn(a,b){var s,r,q,p,o,n=this,m=null
if(a instanceof A.a1){s=a.b
r=a.c
q=a.d
if(q instanceof A.ag||q instanceof A.aR){p=n.bR(A.S(r),b)
o=n.cf(q)
if(typeof o=="number"){if(s==="=")return new A.bj(p,o,o)
if(s===">=")return new A.bj(p,o,m)
if(s===">")return new A.bj(p,o+0.000001,m)
if(s==="<=")return new A.bj(p,m,o)
if(s==="<")return new A.bj(p,m,o-0.000001)}}else if(r instanceof A.ag||r instanceof A.aR){p=n.bR(A.S(q),b)
o=n.cf(r)
if(typeof o=="number"){if(s==="=")return new A.bj(p,o,o)
if(s==="<=")return new A.bj(p,o,m)
if(s==="<")return new A.bj(p,o+0.000001,m)
if(s===">=")return new A.bj(p,m,o)
if(s===">")return new A.bj(p,m,o-0.000001)}}}return m},
ia(a){var s,r,q,p,o,n,m,l,k,j=null,i=a.e,h=i==null?j:i.toLowerCase(),g=a.f,f=g.length!==0?B.b.gH(g):j
if(f==null)s=j
else{f=f.c
s=f==null?j:f.toLowerCase()}f=new A.mv(this,h,a,s)
r=a.a
q=A.z(r).i("h<1,ai>")
p=A.r(new A.h(r,new A.mu(f),q),q.i("u.E"))
if((g.length!==0?B.b.gH(g):j)!=null){r=(g.length!==0?B.b.gH(g):j).a
q=f.$1((g.length!==0?B.b.gH(g):j).d)
o=new A.br(r,j,(g.length!==0?B.b.gH(g):j).c,q,!1,!1,!1)}else o=j
g=a.r
n=g!=null?f.$1(g):j
g=a.w
m=g!=null?f.$1(g):j
g=a.x
l=g!=null?f.$1(g):j
g=a.y
k=g!=null?new A.dD(f.$1(g.a),g.b):j
return A.p3(j,a.d,a.c,m,l,!1,o,j,a.z,j,k,p,i,a.b,n,a.as)},
j0(a,b){var s,r,q,p,o,n,m,l,k,j,i,h,g,f=null,e=this.a,d=e.c.h(0,a.toLowerCase())
if(d==null)return f
for(e=J.as(e.bf(a)),s=t.s,r=t.e,q=r.i("u.E"),p=f,o=p,n=o,m=-1;e.p();){l=e.gD()
k=l.c
if(B.b.cr(A.a(k.split(","),s),new A.mx(d)))j=A.r(new A.h(A.a(k.split(","),s),new A.my(),r),q)
else j=A.a([k.toLowerCase()],s)
if(j.length===0)continue
i=this.el(b,a,j)
if(i!=null){h=i[0]
g=h.length
if(g>m){p=i[1]
m=g
o=h
n=l}}}if(n!=null)return new A.jF(n,o,p)
return f},
el(a,b,c){var s,r,q,p,o=t.n,n=A.a([],o),m=A.a([],o)
for(s=0;s<c.length;++s){r=B.a.V(c[s]).toLowerCase()
q=this.d3(a,b,r)
if(q!=null){n.push(q)
m.push(q)}else if(s===0){p=this.io(a,b)
if(p!=null&&p.a===r){o=p.b
if(o!=null)n.push(o)
o=p.c
if(o!=null)m.push(o)
break}else return null}else break}return A.a([n,m],t.gy)},
d3(a,b,c){var s,r,q,p,o,n=this
if(a instanceof A.a1){s=a.b.toUpperCase()
if(s==="AND"){r=n.d3(a.c,b,c)
if(r!=null)return r
return n.d3(a.d,b,c)}else if(s==="="){q=a.c
p=a.d
o=n.bR(c,b)
if(p instanceof A.ag||p instanceof A.aR)if(n.bR(A.S(q),b)===o)return n.eb(n.cf(p))
if(q instanceof A.ag||q instanceof A.aR)if(n.bR(A.S(p),b)===o)return n.eb(n.cf(q))}}return null},
eb(a){var s,r,q,p
if(typeof a=="number")return a
if(typeof a=="string"){s=A.aH(a)
if(s!=null)return s
for(r=a.length,q=0,p=0;p<r;++p)q=B.c.a7(q*31+a.charCodeAt(p),9007199254740991)
return q}return null},
hI(a){var s,r,q=A.a([],t.fu)
for(s=a.length,r=0;r<a.length;a.length===s||(0,A.n)(a),++r)this.c9(a[r].a,q)
return q},
c9(a,b){var s,r,q
if(a instanceof A.bK)b.push(a)
else if(a instanceof A.a1){this.c9(a.c,b)
this.c9(a.d,b)}else if(a instanceof A.af)for(s=a.c,r=s.length,q=0;q<s.length;s.length===r||(0,A.n)(s),++q)this.c9(s[q],b)},
ci(a,b){var s,r,q,p,o,n,m,l,k,j,i=a.b,h=i.toLowerCase(),g=a.c
if(b.F(h)){g=b.h(0,h)
s=a.e
i=s==null?i:s}if(g!=null)g=this.ci(g,b)
r=A.a([],t.R)
for(q=a.f,p=q.length,o=0;o<q.length;q.length===p||(0,A.n)(q),++o){n=q[o]
m=n.a
l=m.toLowerCase()
k=n.b
if(b.F(l)){k=b.h(0,l)
j=n.c
m=j==null?m:j}if(k!=null)k=this.ci(k,b)
r.push(new A.br(m,k,n.c,n.d,n.e,n.f,n.r))}return A.p3(null,a.d,g,a.w,a.x,a.at,null,r,a.z,a.Q,a.y,a.a,a.e,i,a.r,a.as)},
i5(a,b,c,d){var s,r=new A.hE(this.aM(b),new A.mt(c,d)),q=a.ch,p=q.r,o=p!=null?A.er(r,p):r
p=q.a
if(p.length!==0)o=A.hD(o,p)
p=q.y
if(p!=null)o=A.qn(o,p.a,p.b)
p=q.z
s=p==null
if(!s||q.Q!=null){if(s)p=-1
s=q.Q
o=new A.cK(o,p,s==null?0:s)}return o}}
A.mq.prototype={
$1(a){var s,r,q,p=this
if(a instanceof A.H){s=a.b
if(s.length===1){r=B.b.gH(s).toLowerCase()
s=p.a
if(s.F(r)){s=s.h(0,r)
s.toString
return s}}return a}if(a instanceof A.a1)return new A.a1(a.b,p.$1(a.c),p.$1(a.d))
if(a instanceof A.af){s=a.c
q=A.z(s).i("h<1,L>")
s=A.r(new A.h(s,p,q),q.i("u.E"))
return new A.af(a.b,s)}if(a instanceof A.ba)return new A.ba(p.$1(a.b),a.c,a.d)
return a},
$S:39}
A.ms.prototype={
$1(a){var s,r,q,p
if(!B.a.U(a,"(")||!B.a.B(a,")"))return!1
for(s=a.length-1,r=0,q=0;q<s;++q){p=a[q]
if(p==="(")++r
else if(p===")")--r
if(r===0)return!1}return r===1},
$S:8}
A.mr.prototype={
$1(a){var s=this.a.dx
s===$&&A.b()
return B.b.E(s,B.a.V(a).toLowerCase())},
$S:8}
A.mF.prototype={
$1(a){return this.a.aM(a)},
$S:28}
A.mz.prototype={
$1(a){return this.a.aM(a)},
$S:28}
A.mw.prototype={
$1(a){return this.a.aM(a)},
$S:28}
A.mA.prototype={
$1(a){return A.cw(B.a.V(a))},
$S:16}
A.mB.prototype={
$1(a){return B.a.V(a).toLowerCase()},
$S:7}
A.mC.prototype={
$1(a){return B.a.V(a).toLowerCase()},
$S:7}
A.mD.prototype={
$2(a,b){var s=new A.mE(this.a)
return J.pD(s.$1(a),s.$1(b))},
$S:92}
A.mE.prototype={
$1(a){var s,r,q,p,o,n=a.a.toLowerCase(),m=this.a.a.f.h(0,n.toLowerCase())
if(m==null)return 1e4
s=a.d
if(s instanceof A.a1&&s.b==="="){r=s.c
if(r instanceof A.H&&B.b.gH(r.b).toLowerCase()===n)q=B.b.gW(r.b).toLowerCase()
else{s=s.d
q=s instanceof A.H&&B.b.gH(s.b).toLowerCase()===n?B.b.gW(s.b).toLowerCase():""}}else q=""
s=q.length!==0
if(s&&m.c.F(q))p=m.c.h(0,q).it(0)
else if(s&&m.b.F(q)){o=m.b.h(0,q).c
p=o>0?1/o:0.1}else p=0.1
return m.a*p},
$S:93}
A.mv.prototype={
$1(a){var s,r,q,p,o,n=this
if(a instanceof A.H){s=a.b
if(s.length!==0){r=B.b.gH(s).toLowerCase()
q=n.b
if(q!=null&&r===q){q=A.a([n.c.b],t.s)
B.b.X(q,B.b.ad(s,1))
return new A.H(q)}q=n.d
if(q!=null&&r===q){q=n.c.f
q=A.a([(q.length!==0?B.b.gH(q):null).a],t.s)
B.b.X(q,B.b.ad(s,1))
return new A.H(q)}}return a}if(a instanceof A.ba)return new A.ba(n.$1(a.b),a.c,a.d)
if(a instanceof A.a1)return new A.a1(a.b,n.$1(a.c),n.$1(a.d))
if(a instanceof A.af){s=n.a
q=a.b
p=s.d.$1(q)
if(p!=null){q=a.c
o=A.z(q).i("h<1,L>")
q=A.r(new A.h(q,n,o),o.i("u.E"))
return n.$1(s.hE(p,q))}s=a.c
o=A.z(s).i("h<1,L>")
s=A.r(new A.h(s,n,o),o.i("u.E"))
return new A.af(q,s)}if(a instanceof A.bK){s=a.d
q=A.z(s).i("h<1,L>")
s=A.r(new A.h(s,n,q),q.i("u.E"))
q=a.e
q=q!=null?new A.dD(n.$1(q.a),q.b):null
return new A.bK(a.b,B.cJ,s,q)}return a},
$S:39}
A.mu.prototype={
$1(a){return new A.ai(this.a.$1(a.a),a.b)},
$S:94}
A.mx.prototype={
$1(a){var s=this.a.dx
s===$&&A.b()
return B.b.E(s,B.a.V(a).toLowerCase())},
$S:8}
A.my.prototype={
$1(a){return B.a.V(a).toLowerCase()},
$S:7}
A.mt.prototype={
$1(a){var s=this.a,r=s.r,q=r!=null?A.er(a,r):a
s=s.a
return s.length!==0?A.hD(q,s):q},
$S:95}
A.bj.prototype={}
A.jF.prototype={}
A.j2.prototype={
am(){var s=this,r=s.f,q=A.z(r).i("h<1,w<e,@>>")
r=A.r(new A.h(r,new A.j3(),q),q.i("u.E"))
return A.a7(["sql",s.a,"totalDurationMicroseconds",s.b,"rowsReturned",s.c,"cacheHitRatePercentage",s.d,"peakMemoryBytes",s.e,"steps",r],t.N,t.z)}}
A.j3.prototype={
$1(a){return a.am()},
$S:96}
A.k.prototype={
aw(a,b){var s,r,q,p,o,n=this
if(b==null)return!1
if(n===b)return!0
if(!(b instanceof A.k))return!1
if(n.gae()!==b.gae())return!1
if(n instanceof A.d&&b instanceof A.d)return!0
if(n instanceof A.p&&b instanceof A.p)return n.a===b.a
if(n instanceof A.j&&b instanceof A.j)return n.a===b.a
if(n instanceof A.m&&b instanceof A.m)return n.a===b.a
if(n instanceof A.a5&&b instanceof A.a5){s=n.a
r=b.a
q=J.X(s)
p=J.X(r)
if(q.gt(s)!==p.gt(r))return!1
for(o=0;o<q.gt(s);++o)if(!J.az(q.h(s,o),p.h(r,o)))return!1
return!0}if(n instanceof A.M&&b instanceof A.M)return n.l(0)===b.gaR()
if(n instanceof A.aG&&b instanceof A.aG)return n.a===b.a
if(n instanceof A.bp&&b instanceof A.bp)return n.a===b.a
if(n instanceof A.bo&&b instanceof A.bo)return n.a.aw(0,b.a)
if(n instanceof A.b0&&b instanceof A.b0)return n.a===b.a
if(n instanceof A.a8&&b instanceof A.a8)return n.a===b.a
return!1},
gY(a){var s,r,q=this
if(q instanceof A.d)return 0
if(q instanceof A.p)return B.c.gY(q.a)
if(q instanceof A.j)return B.h.gY(q.a)
if(q instanceof A.m)return B.a.gY(q.a)
if(q instanceof A.a5){for(s=J.as(q.a),r=17;s.p();)r=37*r+J.by(s.gD())
return r}if(q instanceof A.M)return B.a.gY(q.l(0))
if(q instanceof A.aG)return B.cC.gY(q.a)
if(q instanceof A.bp)return B.a.gY(q.a)
if(q instanceof A.bo)return q.a.gY(0)
if(q instanceof A.b0)return B.j.gY(q.a)
if(q instanceof A.a8)return B.h.gY(q.a)
return 0}}
A.iW.prototype={
$1(a){return typeof a=="number"},
$S:97}
A.iX.prototype={
$1(a){return A.ik(a)},
$S:98}
A.d.prototype={
gae(){return B.t},
ga2(){return null},
al(){var s=new Uint8Array(1)
s[0]=0
return s},
A(a,b){if(b instanceof A.d)return 0
return-1},
ap(a,b){return new A.d()},
aG(a,b){return new A.d()},
P(a,b){return new A.d()},
aD(a,b){return new A.d()},
aJ(a){return new A.d()},
l(a){return"NULL"}}
A.p.prototype={
gae(){return B.av},
al(){var s,r,q,p=null,o=this.a
if(o>=-128&&o<=127){s=new Uint8Array(2)
s[0]=1
r=A.at(s,0,p)
r.$flags&2&&A.i(r,6)
r.setInt8(1,o)
return s}else if(o>=-32768&&o<=32767){s=new Uint8Array(3)
q=A.at(s,0,p)
q.$flags&2&&A.i(q,9)
q.setUint8(0,1)
q.setInt16(1,o,!1)
return s}else if(o>=-2147483648&&o<=2147483647){s=new Uint8Array(5)
q=A.at(s,0,p)
q.$flags&2&&A.i(q,9)
q.setUint8(0,1)
q.setInt32(1,o,!1)
return s}else{q=A.at(new Uint8Array(9),0,p)
q.$flags&2&&A.i(q,9)
q.setUint8(0,1)
B.r.c4(q,1,o)}},
A(a,b){if(b instanceof A.d)return 1
if(b instanceof A.p)return B.c.A(this.a,b.a)
if(b instanceof A.j)return B.c.A(this.a,b.a)
return B.a.A(B.c.l(this.a),b.l(0))},
ap(a,b){if(b instanceof A.p)return A.v(this.a+b.a)
if(b instanceof A.j)return new A.j(this.a+b.a)
return new A.d()},
aG(a,b){if(b instanceof A.p)return A.v(this.a-b.a)
if(b instanceof A.j)return new A.j(this.a-b.a)
return new A.d()},
P(a,b){if(b instanceof A.p)return A.v(this.a*b.a)
if(b instanceof A.j)return new A.j(this.a*b.a)
return new A.d()},
aD(a,b){if(b instanceof A.p)return new A.j(this.a/b.a)
if(b instanceof A.j)return new A.j(this.a/b.a)
return new A.d()},
aJ(a){return new A.m(B.c.l(this.a)+a.l(0))},
l(a){return B.c.l(this.a)},
ga2(){return this.a}}
A.j.prototype={
gae(){return B.L},
al(){var s=new Uint8Array(9),r=A.at(s,0,null)
r.$flags&2&&A.i(r,9)
r.setUint8(0,2)
r.setFloat64(1,this.a,!1)
return s},
A(a,b){if(b instanceof A.d)return 1
if(b instanceof A.p)return B.h.A(this.a,b.a)
if(b instanceof A.j)return B.h.A(this.a,b.a)
return B.a.A(B.h.l(this.a),b.l(0))},
ap(a,b){if(b instanceof A.p)return new A.j(this.a+b.a)
if(b instanceof A.j)return new A.j(this.a+b.a)
return new A.d()},
aG(a,b){if(b instanceof A.p)return new A.j(this.a-b.a)
if(b instanceof A.j)return new A.j(this.a-b.a)
return new A.d()},
P(a,b){if(b instanceof A.p)return new A.j(this.a*b.a)
if(b instanceof A.j)return new A.j(this.a*b.a)
return new A.d()},
aD(a,b){if(b instanceof A.p)return new A.j(this.a/b.a)
if(b instanceof A.j)return new A.j(this.a/b.a)
return new A.d()},
aJ(a){return new A.m(B.h.l(this.a)+a.l(0))},
l(a){return B.h.l(this.a)},
ga2(){return this.a}}
A.m.prototype={
gae(){return B.t},
al(){var s=B.x.aB(this.a),r=new Uint8Array(1+s.length)
r[0]=3
B.j.aj(r,1,s)
return r},
A(a,b){if(b instanceof A.d)return 1
return B.a.A(this.a,b.l(0))},
ap(a,b){return new A.m(this.a+b.l(0))},
aG(a,b){return new A.d()},
P(a,b){return new A.d()},
aD(a,b){return new A.d()},
aJ(a){return new A.m(this.a+a.l(0))},
l(a){return this.a},
ga2(){return this.a}}
A.a5.prototype={
gae(){return B.W},
al(){var s,r=this.a,q=J.X(r),p=q.gt(r),o=new Uint8Array(1+p*8),n=A.at(o,0,null)
n.$flags&2&&A.i(n,9)
n.setUint8(0,4)
for(s=0;s<q.gt(r);++s)n.setFloat64(1+s*8,q.h(r,s),!1)
return o},
A(a,b){if(b instanceof A.d)return 1
return B.a.A("["+J.oz(this.a,", ")+"]",b.l(0))},
ap(a,b){return new A.d()},
aG(a,b){return new A.d()},
P(a,b){return new A.d()},
aD(a,b){return new A.d()},
aJ(a){return new A.d()},
l(a){return"["+J.oz(this.a,", ")+"]"},
co(a){var s,r,q,p,o,n,m,l,k,j=this.a,i=a.a,h=J.X(j),g=h.gt(j),f=J.X(i)
if(g!==f.gt(i)||g===0)return 0
s=g-3
for(r=0,q=0;q<s;q+=4){p=h.h(j,q)-f.h(i,q)
o=q+1
n=h.h(j,o)-f.h(i,o)
o=q+2
m=h.h(j,o)-f.h(i,o)
o=q+3
l=h.h(j,o)-f.h(i,o)
r+=p*p+n*n+m*m+l*l}for(;q<g;++q){k=h.h(j,q)-f.h(i,q)
r+=k*k}return Math.sqrt(r)},
cm(a3){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b=this.a,a=a3.a,a0=J.X(b),a1=a0.gt(b),a2=J.X(a)
if(a1!==a2.gt(a)||a1===0)return 1
s=a1-3
for(r=0,q=0,p=0,o=0;o<s;o+=4){n=a0.h(b,o)
m=a2.h(a,o)
l=o+1
k=a0.h(b,l)
j=a2.h(a,l)
l=o+2
i=a0.h(b,l)
h=a2.h(a,l)
l=o+3
g=a0.h(b,l)
f=a2.h(a,l)
r+=n*m+k*j+i*h+g*f
q+=n*n+k*k+i*i+g*g
p+=m*m+j*j+h*h+f*f}for(;o<a1;++o){e=a0.h(b,o)
d=a2.h(a,o)
r+=e*d
q+=e*e
p+=d*d}if(q===0||p===0)return 1
c=Math.sqrt(q)*Math.sqrt(p)
if(c===0)return 1
return 1-r/c},
cp(a){var s,r,q,p,o,n,m=this.a,l=a.a,k=J.X(m),j=k.gt(m),i=J.X(l)
if(j!==i.gt(l)||j===0)return 0
s=j-3
for(r=0,q=0;q<s;q+=4){p=q+1
o=q+2
n=q+3
r+=k.h(m,q)*i.h(l,q)+k.h(m,p)*i.h(l,p)+k.h(m,o)*i.h(l,o)+k.h(m,n)*i.h(l,n)}for(;q<j;++q)r+=k.h(m,q)*i.h(l,q)
return-r},
ga2(){return this.a}}
A.M.prototype={
gae(){return B.M},
gaR(){var s=this,r=s.b
if(r==null){r=s.c
if(r!=null){r=B.a5.ag(r)
s.b=r}else{r=B.o.bB(s.a)
s.b=r}}return r},
ga2(){var s=this.a
return s==null?this.a=B.o.ag(this.gaR()):s},
al(){var s,r,q,p=this.c
if(p!=null){s=p.length
r=new Uint8Array(1+s)
r[0]=5
B.j.aj(r,1,p)
return r}q=B.x.aB(this.gaR())
r=new Uint8Array(1+q.length)
r[0]=5
B.j.aj(r,1,q)
return r},
A(a,b){if(b instanceof A.d)return 1
return B.a.A(this.gaR(),b.l(0))},
aY(a){if(this.a==null)return A.w5(this.gaR(),a)
return this.em(a)},
em(a){var s,r,q,p,o,n,m=this.ga2()
for(s=a.length,r=t.j,q=t.f,p=0;p<a.length;a.length===s||(0,A.n)(a),++p){o=a[p]
if(q.b(m)&&m.F(o))m=m.h(0,o)
else if(r.b(m)){n=A.a4(o,null)
if(n!=null&&n>=0&&n<J.O(m))m=J.Y(m,n)
else return new A.d()}else return new A.d()}return A.cd(m)},
ap(a,b){return new A.d()},
aG(a,b){return new A.d()},
P(a,b){return new A.d()},
aD(a,b){return new A.d()},
aJ(a){return new A.d()},
l(a){return this.gaR()}}
A.aN.prototype={
h(a,b){var s
if(typeof b=="string"){s=this.b.h(0,b)
if(s!=null&&s<this.a.length)return this.a[s]}return null},
k(a,b,c){var s,r=this.b.h(0,b)
if(r!=null&&r<this.a.length){s=this.a
s.$flags&2&&A.i(s)
s[r]=c}},
gZ(){return this.b.gZ()},
S(a,b){return null},
gaP(){return this.a}}
A.aP.prototype={
gae(){return B.M},
ga2(){return this.a},
al(){return new Uint8Array(0)},
A(a,b){var s,r,q,p,o,n
if(b instanceof A.aP){s=this.a
r=s.length
q=b.a
p=q.length
if(r!==p)return B.c.A(r,p)
for(o=0;o<s.length;++o){n=s[o].A(0,q[o])
if(n!==0)return n}return 0}return-1},
ap(a,b){return new A.d()},
aG(a,b){return new A.d()},
P(a,b){return new A.d()},
aD(a,b){return new A.d()},
aJ(a){return new A.d()},
l(a){var s=this.a
return"["+new A.h(s,new A.iV(),A.z(s).i("h<1,e>")).R(0,", ")+"]"}}
A.iV.prototype={
$1(a){return a.l(0)},
$S:20}
A.aG.prototype={
gae(){return B.a6},
al(){var s=new Uint8Array(2)
s[0]=8
s[1]=this.a?1:0
return s},
A(a,b){var s
if(b instanceof A.aG){s=this.a
if(s===b.a)return 0
return s?1:-1}if(b instanceof A.p){s=this.a?1:0
return B.c.A(s,b.a)}return 1},
ap(a,b){return new A.d()},
aG(a,b){return new A.d()},
P(a,b){return new A.d()},
aD(a,b){return new A.d()},
aJ(a){var s=this.a?"true":"false"
return new A.m(s+a.l(0))},
l(a){return this.a?"true":"false"},
ga2(){return this.a}}
A.bp.prototype={
gae(){return B.a7},
al(){var s=B.x.aB(this.a),r=new Uint8Array(1+s.length)
r[0]=9
B.j.aj(r,1,s)
return r},
A(a,b){if(b instanceof A.bp)return B.a.A(this.a,b.a)
return B.a.A(this.a,b.l(0))},
ap(a,b){return new A.d()},
aG(a,b){return new A.d()},
P(a,b){return new A.d()},
aD(a,b){return new A.d()},
aJ(a){return new A.m(this.a+a.l(0))},
l(a){return this.a},
ga2(){return this.a}}
A.bo.prototype={
gae(){return B.a8},
al(){var s=new DataView(new ArrayBuffer(9))
s.setUint8(0,10)
B.r.c4(s,1,this.a.a)},
A(a,b){var s
if(b instanceof A.bo)return this.a.A(0,b.a)
if(b instanceof A.m){s=A.bA(b.a)
if(s!=null)return this.a.A(0,s)}return B.a.A(this.a.bt(),b.l(0))},
ap(a,b){return new A.d()},
aG(a,b){return new A.d()},
P(a,b){return new A.d()},
aD(a,b){return new A.d()},
aJ(a){return new A.m(this.a.bt()+a.l(0))},
l(a){return this.a.bt()},
ga2(){return this.a}}
A.b0.prototype={
gae(){return B.a9},
al(){var s=this.a,r=new Uint8Array(1+s.length)
r[0]=11
B.j.aj(r,1,s)
return r},
A(a,b){var s,r,q,p,o,n,m
if(b instanceof A.b0){s=this.a
r=s.length
q=b.a
p=q.length
o=Math.min(r,p)
for(n=0;n<o;++n){m=B.c.A(s[n],q[n])
if(m!==0)return m}return B.c.A(r,p)}return-1},
ap(a,b){return new A.d()},
aG(a,b){return new A.d()},
P(a,b){return new A.d()},
aD(a,b){return new A.d()},
aJ(a){var s,r,q,p
if(a instanceof A.b0){s=this.a
r=s.length
q=a.a
p=new Uint8Array(r+q.length)
B.j.aj(p,0,s)
B.j.aj(p,r,q)
return new A.b0(p)}return new A.d()},
l(a){var s=this.a
return"X'"+new A.h(s,new A.iU(),A.bO(s).i("h<a3.E,e>")).dE(0)+"'"},
ga2(){return this.a}}
A.iU.prototype={
$1(a){return B.a.a1(B.c.fw(a,16),2,"0")},
$S:6}
A.a8.prototype={
gae(){return B.aa},
al(){var s=new DataView(new ArrayBuffer(9))
s.setUint8(0,12)
s.setFloat64(1,this.a,!1)
return J.oy(B.r.gai(s))},
A(a,b){var s,r=this
if(b instanceof A.a8)return B.h.A(r.a,b.a)
if(b instanceof A.p)return B.h.A(r.a,b.a)
if(b instanceof A.j)return B.h.A(r.a,b.a)
s=A.aH(b.l(0))
if(s==null)s=0
return B.h.A(r.a,s)},
ap(a,b){if(b instanceof A.a8)return new A.a8(this.a+b.a)
if(b instanceof A.p)return new A.a8(this.a+b.a)
if(b instanceof A.j)return new A.a8(this.a+b.a)
return new A.d()},
aG(a,b){if(b instanceof A.a8)return new A.a8(this.a-b.a)
if(b instanceof A.p)return new A.a8(this.a-b.a)
if(b instanceof A.j)return new A.a8(this.a-b.a)
return new A.d()},
P(a,b){if(b instanceof A.a8)return new A.a8(this.a*b.a)
if(b instanceof A.p)return new A.a8(this.a*b.a)
if(b instanceof A.j)return new A.a8(this.a*b.a)
return new A.d()},
aD(a,b){if(b instanceof A.a8)return new A.a8(this.a/b.a)
if(b instanceof A.p)return new A.a8(this.a/b.a)
if(b instanceof A.j)return new A.a8(this.a/b.a)
return new A.d()},
aJ(a){return new A.m(B.h.l(this.a)+a.l(0))},
l(a){return B.h.l(this.a)},
ga2(){return this.a}}
A.av.prototype={
cb(){return"DataType."+this.b}}
A.y.prototype={}
A.L.prototype={}
A.ag.prototype={}
A.aR.prototype={}
A.H.prototype={}
A.a1.prototype={}
A.af.prototype={}
A.bK.prototype={}
A.cr.prototype={}
A.ba.prototype={}
A.co.prototype={}
A.dO.prototype={}
A.dj.prototype={}
A.cF.prototype={}
A.e4.prototype={}
A.b_.prototype={}
A.ai.prototype={}
A.br.prototype={}
A.dD.prototype={}
A.G.prototype={}
A.hS.prototype={}
A.hw.prototype={}
A.hx.prototype={}
A.dg.prototype={}
A.dc.prototype={}
A.eF.prototype={}
A.d7.prototype={
cb(){return"AlterAction."+this.b}}
A.bP.prototype={}
A.cH.prototype={}
A.dk.prototype={}
A.fj.prototype={}
A.aS.prototype={
giQ(a){var s=this.f
return s.length!==0?B.b.gH(s):null}}
A.di.prototype={}
A.cS.prototype={}
A.du.prototype={}
A.dm.prototype={}
A.hT.prototype={}
A.h_.prototype={}
A.ce.prototype={}
A.dH.prototype={}
A.e6.prototype={}
A.h2.prototype={}
A.ew.prototype={}
A.fm.prototype={}
A.eh.prototype={}
A.e7.prototype={}
A.eb.prototype={}
A.f0.prototype={}
A.ev.prototype={}
A.eZ.prototype={}
A.f4.prototype={}
A.f3.prototype={}
A.ef.prototype={}
A.fk.prototype={}
A.df.prototype={}
A.dd.prototype={}
A.dq.prototype={}
A.ep.prototype={}
A.d8.prototype={}
A.f8.prototype={}
A.f6.prototype={}
A.de.prototype={}
A.hv.prototype={}
A.cB.prototype={}
A.cA.prototype={}
A.e9.prototype={}
A.eX.prototype={}
A.dN.prototype={}
A.f2.prototype={}
A.f_.prototype={}
A.eW.prototype={}
A.eN.prototype={}
A.eq.prototype={}
A.ea.prototype={}
A.dh.prototype={}
A.dU.prototype={}
A.d9.prototype={}
A.cb.prototype={}
A.ej.prototype={}
A.cC.prototype={}
A.f5.prototype={}
A.f7.prototype={}
A.eP.prototype={}
A.fh.prototype={}
A.ei.prototype={}
A.et.prototype={}
A.cc.prototype={}
A.eg.prototype={}
A.el.prototype={}
A.oh.prototype={
$1(a){return"("+J.bG(a,A.io(),t.N).R(0,", ")+")"},
$S:99}
A.c_.prototype={
hS(){var s=this.b+1,r=this.a
return s>=r.length?"":r[s]},
ah(){var s,r=this,q=r.b,p=r.a
if(q>=p.length)return""
r.b=q+1
s=p[q]
if(s==="\n"){++r.c
r.d=1}else ++r.d
return s},
bu(){var s,r,q,p=this
if(p.b===0){s=p.a
if(B.a.U(s,"\ufeff"))p.b=1
else if(B.a.U(s,"\xef\xbb\xbf"))p.b=3}r=A.a([],t.aT)
for(s=p.a.length;p.b<s;){q=p.hV()
r.push(q)
if(q.a===B.k)break}if(r.length===0||B.b.gW(r).a!==B.k)r.push(new A.N(B.k,"",p.c,p.d))
return r},
hV(){var s,r,q,p,o,n,m,l,k,j,i=this
i.il()
s=i.a
r=s.length
if(i.b>=r)return new A.N(B.k,"",i.c,i.d)
q=i.c
p=i.d
o=i.ah()
if(i.ex(o)){n=o
for(;;){m=i.b
m=m>=r?"":s[m]
if(!(i.ex(m)||i.bz(m)))break
n+=i.ah()}l=n.charCodeAt(0)==0?n:n
k=B.cK.h(0,l.toLowerCase())
return new A.N(k==null?B.d:k,l,q,p)}if(i.bz(o)){n=o
for(;;){m=i.b
if(!i.bz(m>=r?"":s[m]))break
n+=i.ah()}m=i.b
if((m>=r?"":s[m])==="."&&i.bz(i.hS())){n+=i.ah()
for(;;){m=i.b
if(!i.bz(m>=r?"":s[m]))break
n+=i.ah()}s=n}else s=n
return new A.N(B.a3,s.charCodeAt(0)==0?s:s,q,p)}if(o==="'"){n=""
for(;;){m=i.b
j=m>=r
if(!((j?"":s[m])!=="'"&&!j))break
n+=i.ah()}if(j)return new A.N(B.K,"Unterminated string literal",q,p)
i.ah()
return new A.N(B.q,n.charCodeAt(0)==0?n:n,q,p)}switch(o){case"(":return new A.N(B.l,"(",q,p)
case")":return new A.N(B.i,")",q,p)
case"[":return new A.N(B.cm,"[",q,p)
case"]":return new A.N(B.aX,"]",q,p)
case",":return new A.N(B.n,",",q,p)
case";":return new A.N(B.e,";",q,p)
case".":return new A.N(B.J,".",q,p)
case"+":return new A.N(B.cb,"+",q,p)
case"-":n=i.b
if((n>=r?"":s[n])===">"){i.ah()
n=i.b
if((n>=r?"":s[n])===">"){i.ah()
return new A.N(B.ck,"->>",q,p)}return new A.N(B.cj,"->",q,p)}return new A.N(B.ar,"-",q,p)
case"*":return new A.N(B.as,"*",q,p)
case"/":return new A.N(B.cc,"/",q,p)
case"%":return new A.N(B.ci,"%",q,p)
case"=":return new A.N(B.B,"=",q,p)
case"<":n=i.b
r=n>=r
if((r?"":s[n])==="="){i.ah()
return new A.N(B.cf,"<=",q,p)}else if((r?"":s[n])===">"){i.ah()
return new A.N(B.aV,"<>",q,p)}return new A.N(B.cd,"<",q,p)
case">":n=i.b
if((n>=r?"":s[n])==="="){i.ah()
return new A.N(B.cg,">=",q,p)}return new A.N(B.ce,">",q,p)
case"!":n=i.b
if((n>=r?"":s[n])==="="){i.ah()
return new A.N(B.aV,"!=",q,p)}return new A.N(B.K,"!",q,p)
case":":n=i.b
r=n>=r
if((r?"":s[n])==="="){i.ah()
return new A.N(B.at,":=",q,p)}else if((r?"":s[n])===":"){i.ah()
return new A.N(B.cl,"::",q,p)}return new A.N(B.K,":",q,p)
case"|":n=i.b
if((n>=r?"":s[n])==="|"){i.ah()
return new A.N(B.ch,"||",q,p)}return new A.N(B.K,"|",q,p)
case"~":return new A.N(B.bO,"~",q,p)
case"?":return new A.N(B.aY,"?",q,p)
case"$":n=o
for(;;){m=i.b
if(!i.bz(m>=r?"":s[m]))break
n+=i.ah()}if(n.length>1)return new A.N(B.aY,n.charCodeAt(0)==0?n:n,q,p)
return new A.N(B.K,"$",q,p)}return new A.N(B.K,o,q,p)},
il(){var s,r,q,p,o,n=this
for(s=n.a,r=s.length;q=n.b,p=q>=r,!p;){o=p?"":s[q]
if(o===" "||o==="\r"||o==="\t"||o==="\n")n.ah()
else{if(o==="-"){++q
q=(q>=r?"":s[q])==="-"}else q=!1
if(q)for(;;){q=n.b
p=q>=r
if(!((p?"":s[q])!=="\n"&&!p))break
n.ah()}else break}}},
ex(a){var s,r
if(a.length===0)return!1
s=a.charCodeAt(0)
if(!(s>=65&&s<=90))r=s>=97&&s<=122||s===95
else r=!0
return r},
bz(a){var s
if(a.length===0)return!1
s=a.charCodeAt(0)
return s>=48&&s<=57}}
A.c1.prototype={
bS(){return this.a[this.b]},
aV(){var s=this.b+1,r=this.a
return s<r.length?r[s]:B.b.gW(r)},
q(){var s=this.a,r=this.b
return s[(s[r].a!==B.k?this.b=r+1:r)-1]},
n(a){var s=this.a[this.b].a
if(s===B.k)return!1
return s===a},
m(a){var s,r,q=this
for(s=a.length,r=0;r<a.length;a.length===s||(0,A.n)(a),++r)if(q.n(a[r])){s=q.b
if(q.a[s].a!==B.k)q.b=s+1
return!0}return!1},
j(a,b){if(this.n(a))return this.q()
throw A.c(A.q("["+this.bS().l(0)+"] "+b))},
aH(a){var s=this.a[this.b]
if(s.a!==B.k&&s.b.toLowerCase()===a.toLowerCase()){this.q()
return!0}return!1},
e2(){var s=this.b+1,r=this.a
if(s>=r.length)return!1
s=r[s]
return s.a===B.e||s.b.toLowerCase()==="transaction"},
e1(){var s,r=this.b+1,q=this.a
if(r>=q.length)return!1
r=q[r]
s=r.a
return s===B.H||s===B.S||s===B.I||s===B.am||s===B.an||B.cR.E(0,r.b.toLowerCase())},
fp(){var s,r,q,p=this,o=A.a([],t.m)
for(s=p.a,r=t.B;s[p.b].a!==B.k;){if(!p.n(B.Q))q=p.n(B.w)&&p.e2()
else q=!0
if(q)if(p.n(B.Q))o.push(p.di())
else o.push(p.eK())
else if(p.n(B.w))o.push(p.di())
else o.push(p.au())
while(p.m(A.a([B.e],r)));}return o},
dI(){var s=this.fp()
if(s.length===0)throw A.c(A.q("No statements found in script."))
return B.b.gH(s)},
di(){var s,r,q,p,o,n,m,l,k=this,j=A.a([],t.a4),i=A.a([],t.aF),h=t.B
if(k.m(A.a([B.Q],h))){s=k.a
for(;;){if(!(!k.n(B.w)&&s[k.b].a!==B.k))break
if(k.n(B.d))if(k.aV().a===B.aE){r=k.j(B.d,"Expected cursor name.")
k.j(B.aE,"Expected 'CURSOR' keyword.")
k.j(B.X,"Expected 'FOR' after 'CURSOR'.")
k.j(B.v,"Expected 'SELECT' for cursor query.")
q=k.bo()
if(k.n(B.e)){p=k.b
if(s[p].a!==B.k)k.b=p+1}i.push(new A.h_(r.b,q))}else if(k.e1())j.push(k.eG())
else break
else break}}s=t.m
if(k.n(B.w)){k.j(B.w,"Expected 'BEGIN' to start executable block.")
o=A.a([],s)
p=k.a
for(;;){if(!(!k.n(B.p)&&!k.n(B.aG)&&p[k.b].a!==B.k))break
o.push(k.au())}if(k.m(A.a([B.aG],h))){n=A.a([],t.aY)
for(;;){if(!(!k.n(B.p)&&p[k.b].a!==B.k))break
k.j(B.ad,"Expected 'WHEN' in EXCEPTION block.")
m=k.j(B.d,"Expected exception name.")
k.j(B.Z,"Expected 'THEN' after exception condition.")
l=A.a([],s)
for(;;){if(!(!k.n(B.ad)&&!k.n(B.p)&&p[k.b].a!==B.k))break
l.push(k.au())}n.push(new A.ce(m.b,l))}}else n=null
k.j(B.p,"Expected 'END' to close block.")
k.j(B.e,"Expected ';' after 'END'.")
return new A.dH(j,i,o,n)}else return new A.dH(j,i,A.a([],s),null)},
eG(){var s=this,r=s.j(B.d,"Expected variable name."),q=s.ba(),p=s.m(A.a([B.at,B.B],t.B))?s.M():null
s.j(B.e,"Expected ';' after variable declaration.")
return new A.hT(r.b,q,p)},
ba(){var s,r,q=this,p=t.B
if(q.m(A.a([B.H,B.S,B.I,B.am,B.an,B.ao,B.ap,B.a1,B.a2,B.aq],p)))s=q.a[q.b-1]
else if(q.n(B.d))s=q.q()
else throw A.c(A.q("Unsupported or missing variable type at '"+q.bS().b+"'."))
if(q.m(A.a([B.l],p))){q.M()
while(q.m(A.a([B.n],p)))q.M()
q.j(B.i,"Expected ')' after type modifier.")}r=s.b.toLowerCase()
if(r==="int"||r==="integer"||r==="bigint"||r==="smallint")return B.av
else if(r==="double"||r==="real"||r==="float")return B.L
else if(r==="decimal"||r==="numeric")return B.aa
else if(r==="text"||r==="varchar"||r==="char"||r==="string")return B.t
else if(r==="vector")return B.W
else if(r==="json")return B.M
else if(r==="bool"||r==="boolean")return B.a6
else if(r==="uuid"||r==="guid")return B.a7
else if(r==="datetime"||r==="timestamp"||r==="date")return B.a8
else if(r==="blob"||r==="bytea"||r==="bytes")return B.a9
throw A.c(A.q("Unsupported data type '"+r+"'."))},
au(){var s,r,q,p,o,n,m,l=this
if(!l.n(B.Q))s=l.n(B.w)&&!l.e2()
else s=!0
if(s)return l.di()
s=t.B
if(l.m(A.a([B.bl],s))){s=l.j(B.d,"Expected cursor name after OPEN.")
if(l.n(B.e))l.q()
return new A.eN(s.b)}if(l.m(A.a([B.bm],s))){r=l.j(B.d,"Expected cursor name after FETCH.")
l.j(B.aH,"Expected 'INTO' after cursor name in FETCH.")
q=A.a([],t.s)
do q.push(l.j(B.d,"Expected variable name in FETCH INTO.").b)
while(l.m(A.a([B.n],s)))
if(l.n(B.e))l.q()
return new A.eq(r.b,q)}if(l.m(A.a([B.bn],s))){s=l.j(B.d,"Expected cursor name after CLOSE.")
if(l.n(B.e))l.q()
return new A.ea(s.b)}if(l.n(B.R))return l.i_()
if(!l.n(B.X))s=l.n(B.d)&&l.a[l.b].b.toLowerCase()==="for"
else s=!0
if(s)return l.hZ()
if(l.n(B.aU))return l.i3()
if(l.n(B.az)){l.j(B.az,"Expected 'RETURN'.")
p=l.M()
l.j(B.e,"Expected ';' after return statement.")
return new A.eX(p)}if(l.n(B.d)){o=l.a[l.b].b.toLowerCase()
if(!B.cS.E(0,o)){if(o==="dbms_output"){l.j(B.d,"Expected 'DBMS_OUTPUT'.")
l.j(B.J,"Expected '.' after 'DBMS_OUTPUT'.")
s=l.j(B.d,"Expected 'PUT_LINE'.").b
if(s.toLowerCase()!=="put_line")A.al(A.q("Expected 'PUT_LINE' call, found '"+s+"'."))
l.j(B.l,"Expected '(' for function call.")
p=l.M()
l.j(B.i,"Expected ')' to close function call.")
l.j(B.e,"Expected ';' after PUT_LINE.")
return new A.eh(p)}if(o==="set"){n=l.aV().b.toLowerCase()
if(!(n==="user"||n==="current_user"||n==="engine_option")){l.q()
return l.eD()}}else return l.eD()}}m=l.eK()
if(l.n(B.e))l.q()
return m},
i_(){var s,r,q,p,o,n,m,l,k,j=this
j.j(B.R,"Expected 'IF'.")
s=j.M()
j.j(B.Z,"Expected 'THEN' after condition.")
r=t.m
q=A.a([],r)
p=j.a
for(;;){if(!(!j.n(B.ak)&&!j.n(B.a_)&&!j.n(B.p)&&p[j.b].a!==B.k))break
q.push(j.au())}o=A.a([],t.dK)
for(n=t.B;j.m(A.a([B.ak],n));){m=j.M()
j.j(B.Z,"Expected 'THEN' after ELSIF condition.")
l=A.a([],r)
for(;;){if(!(!j.n(B.ak)&&!j.n(B.a_)&&!j.n(B.p)&&p[j.b].a!==B.k))break
l.push(j.au())}o.push(new A.h2(m,l))}if(j.m(A.a([B.a_],n))){k=A.a([],r)
for(;;){if(!(!j.n(B.p)&&p[j.b].a!==B.k))break
k.push(j.au())}}else k=null
j.j(B.p,"Expected 'END' for IF statement.")
j.j(B.R,"Expected 'IF' after 'END'.")
j.j(B.e,"Expected ';' after 'END IF'.")
return new A.ew(s,q,o,k)},
i3(){var s,r,q,p,o=this
o.j(B.aU,"Expected 'WHILE'.")
s=o.M()
r=o.n(B.w)
if(r)o.j(B.w,"Expected 'BEGIN' after WHILE condition.")
else o.j(B.a0,"Expected 'LOOP' or 'BEGIN' after WHILE condition.")
q=A.a([],t.m)
p=o.a
for(;;){if(!(!o.n(B.p)&&p[o.b].a!==B.k))break
q.push(o.au())}o.j(B.p,"Expected 'END' to close block.")
if(r){if(o.n(B.e))o.q()}else{o.j(B.a0,"Expected 'LOOP' after 'END'.")
o.j(B.e,"Expected ';' after 'END LOOP'.")}return new A.fm(s,q)},
hZ(){var s,r,q,p,o,n=this
n.q()
s=n.j(B.d,"Expected loop variable name.")
if(!n.n(B.ah))r=n.n(B.d)&&n.a[n.b].b.toLowerCase()==="in"
else r=!0
if(r)n.q()
q=n.M()
if(n.m(A.a([B.J],t.B)))if(n.n(B.J))n.q()
p=n.M()
if(!n.n(B.a0))r=n.n(B.d)&&n.a[n.b].b.toLowerCase()==="loop"
else r=!0
if(r)n.q()
o=A.a([],t.m)
r=n.a
for(;;){if(!(!n.n(B.p)&&r[n.b].a!==B.k))break
o.push(n.au())}n.j(B.p,"Expected 'END' to close FOR loop.")
if(!n.n(B.a0))r=n.n(B.d)&&r[n.b].b.toLowerCase()==="loop"
else r=!0
if(r)n.q()
if(n.n(B.e))n.q()
return new A.et(s.b,q,p,o)},
eD(){var s,r,q=this,p=q.j(B.d,"Expected variable name.").b
for(s=t.B;q.m(A.a([B.J],s));)p+="."+q.j(B.d,"Expected segment after dot.").b
if(!q.m(A.a([B.at,B.B],s)))throw A.c(A.q("Expected ':=' or '=' for assignment."))
r=q.M()
q.j(B.e,"Expected ';' after assignment.")
return new A.e6(p,r)},
eK(){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e=this,d="Expected table name to analyze.",c="Expected 'FROM' after 'DELETE'.",b="Expected table name.",a="Expected savepoint name."
e.c=0
s=t.B
if(e.m(A.a([B.bR],s))||e.aH("emit")){if(!e.m(A.a([B.O],s)))e.aH("to")
r=e.j(B.d,"Expected stream name after EMIT TO.")
e.j(B.af,"Expected 'VALUES' after stream name.")
e.j(B.l,"Expected '(' for stream emit values.")
q=A.a([],t.U)
do q.push(e.M())
while(e.m(A.a([B.n],s)))
e.j(B.i,"Expected ')' after stream emit values.")
if(e.n(B.e))e.q()
return new A.el(r.b,q)}if(e.m(A.a([B.bC],s))){e.m(A.a([B.bD],s))
e.j(B.d,"Expected table name after VACUUM.")
if(e.n(B.e))e.q()
return new A.hS()}if(e.m(A.a([B.aT],s)))if(e.m(A.a([B.N],s))){if(e.m(A.a([B.R],s)))p=e.m(A.a([B.aN],s))
else if(e.n(B.d)&&e.a[e.b].b.toLowerCase()==="if"){e.q()
p=e.n(B.d)&&e.a[e.b].b.toLowerCase()==="exists"
if(p)e.q()}else p=!1
s=e.j(B.d,"Expected table name after 'DROP TABLE'.")
if(e.n(B.e))e.q()
return new A.ej(s.b,p)}else if(e.m(A.a([B.aQ],s))){s=e.j(B.d,"Expected index name after 'DROP INDEX'.")
if(e.n(B.e))e.q()
return new A.ei(s.b)}if(e.m(A.a([B.bJ],s))){o=e.j(B.d,"Expected table name after DESCRIBE.")
if(e.n(B.e))e.q()
return new A.cC(o.b)}if(e.n(B.d)&&e.a[e.b].b.toLowerCase()==="desc"){e.q()
o=e.j(B.d,"Expected table name after DESC.")
if(e.n(B.e))e.q()
return new A.cC(o.b)}if(e.m(A.a([B.bI],s)))if(e.j(B.d,"Expected pragma name.").b.toLowerCase()==="table_info"){e.j(B.l,"Expected '(' after table_info.")
if(e.m(A.a([B.q],s))){n=e.a[e.b-1].b
if(B.a.U(n,"'")||B.a.U(n,'"'))n=B.a.O(n,1,n.length-1)}else n=e.j(B.d,"Expected table name in PRAGMA table_info.").b
e.j(B.i,"Expected ')' after table name in PRAGMA table_info.")
if(e.n(B.e))e.q()
return new A.eP(n)}if(e.m(A.a([B.bK],s))){e.m(A.a([B.N],s))
o=e.j(B.d,"Expected table name after TRUNCATE.")
if(e.n(B.e))e.q()
return new A.fh(o.b)}if(e.m(A.a([B.c5],s)))return e.hW()
if(e.m(A.a([B.bb],s))){e.j(B.v,"Expected 'SELECT' after 'EXPLAIN'.")
return new A.ep(e.bo())}if(e.m(A.a([B.P],s))){s=e.a[e.b]
if(s.a!==B.k&&s.b.toLowerCase()==="data")e.q()
if(e.n(B.e))e.q()
return new A.dq()}if(e.m(A.a([B.ax],s))){s=e.j(B.d,d)
if(e.n(B.e))e.q()
return new A.d8(s.b)}if(e.m(A.a([B.aA],s)))return e.eE()
if(e.m(A.a([B.P],s))){s=e.a[e.b]
if(s.a!==B.k&&s.b.toLowerCase()==="data")e.q()
if(e.n(B.e))e.q()
return new A.dq()}if(e.m(A.a([B.ax],s))){s=e.j(B.d,d)
if(e.n(B.e))e.q()
return new A.d8(s.b)}if(e.m(A.a([B.aA],s)))return e.eE()
if(e.m(A.a([B.bf],s)))return e.hX()
if(e.m(A.a([B.aF],s))){if(e.aH("or")&&e.aH("replace"))return e.dh(!0)
return e.i0()}if(e.m(A.a([B.aO],s))||e.aH("replace"))return e.dh(!0)
if(e.m(A.a([B.A],s)))return e.hY()
if(e.m(A.a([B.v],s)))return e.eJ()
if(e.m(A.a([B.Y],s))){e.j(B.C,c)
r=e.j(B.d,b)
m=e.m(A.a([B.G],s))?e.M():null
if(e.n(B.e))e.q()
return new A.dk(r.b,m)}if(e.m(A.a([B.Y],s))){e.j(B.C,c)
r=e.j(B.d,b)
m=e.m(A.a([B.G],s))?e.M():null
if(e.n(B.e))e.q()
return new A.dk(r.b,m)}if(e.n(B.d)&&e.a[e.b].b.toLowerCase()==="update"){e.q()
r=e.j(B.d,b)
if(e.j(B.d,"Expected 'SET' keyword.").b.toLowerCase()!=="set")throw A.c(A.q("Expected 'SET' keyword after table name in UPDATE statement."))
l=e.j(B.d,"Expected column name to update.")
e.j(B.B,"Expected '=' after column name.")
k=e.M()
m=e.m(A.a([B.G],s))?e.M():null
if(e.n(B.e))e.q()
return new A.fj(r.b,l.b,k,m)}if(e.m(A.a([B.w],s))){s=e.a[e.b]
if(s.a!==B.k&&s.b.toLowerCase()==="transaction")e.q()
if(e.n(B.e))e.q()
return new A.e7()}if(e.m(A.a([B.bS],s))){s=e.a[e.b]
if(s.a!==B.k){s=s.b
s=s.toLowerCase()==="transaction"||s.toLowerCase()==="work"}else s=!1
if(s)e.q()
if(e.n(B.e))e.q()
return new A.eb()}if(e.m(A.a([B.bj],s))){j=e.j(B.d,a)
if(e.n(B.e))e.q()
return new A.f2(j.b)}if(e.m(A.a([B.bk],s))){s=e.a[e.b]
if(s.a!==B.k&&s.b.toLowerCase()==="savepoint")e.q()
j=e.j(B.d,a)
if(e.n(B.e))e.q()
return new A.eW(j.b)}if(e.m(A.a([B.bT],s))){s=e.a
r=s[e.b]
l=r.a!==B.k
if(l&&r.b.toLowerCase()==="to"){e.q()
s=s[e.b]
if(s.a!==B.k&&s.b.toLowerCase()==="savepoint")e.q()
j=e.j(B.d,a)
if(e.n(B.e))e.q()
return new A.f_(j.b)}if(l){s=r.b
s=s.toLowerCase()==="transaction"||s.toLowerCase()==="work"}else s=!1
if(s)e.q()
if(e.n(B.e))e.q()
return new A.f0()}if(e.m(A.a([B.bW],s)))return e.i2()
s=e.a
i=s[e.b].b.toLowerCase()
if(i==="grant"){e.q()
if(s[e.b].b.toLowerCase()==="all"){e.q()
if(s[e.b].b.toLowerCase()==="privileges")e.q()
h="all"}else h=e.q().b.toLowerCase()
e.j(B.z,"Expected 'ON' after privilege in GRANT statement.")
s=e.j(B.d,"Expected table name in GRANT statement.")
e.j(B.O,"Expected 'TO' in GRANT statement.")
g=e.n(B.q)?e.j(B.q,"").b:e.j(B.d,"Expected username in GRANT statement.").b
if(e.n(B.e))e.q()
return new A.ev(h,s.b,g)}if(i==="revoke"){e.q()
if(s[e.b].b.toLowerCase()==="all"){e.q()
if(s[e.b].b.toLowerCase()==="privileges")e.q()
h="all"}else h=e.q().b.toLowerCase()
e.j(B.z,"Expected 'ON' after privilege in REVOKE statement.")
s=e.j(B.d,"Expected table name in REVOKE statement.")
e.j(B.C,"Expected 'FROM' in REVOKE statement.")
g=e.n(B.q)?e.j(B.q,"").b:e.j(B.d,"Expected username in REVOKE statement.").b
if(e.n(B.e))e.q()
return new A.eZ(h,s.b,g)}if(i==="set"){e.q()
return e.i1()}if(i==="use"){e.q()
f=e.j(B.d,"Expected database name.")
if(e.n(B.e))e.q()
return new A.fk(f.b)}throw A.c(A.q("Unsupported statement beginning with '"+e.bS().b+"'."))},
i1(){var s,r,q,p,o,n,m=this,l=m.a[m.b].b.toLowerCase()
if(l==="user"||l==="current_user"){m.q()
if(m.n(B.B))m.q()
s=m.n(B.q)?m.j(B.q,"").b:m.j(B.d,"Expected username in SET USER statement.").b
if(m.n(B.e))m.q()
return new A.f4(s)}else if(l==="engine_option"){m.q()
r=m.j(B.q,"Expected string literal for option name.")
m.j(B.B,"Expected '=' after option name.")
q=m.q()
p=A.T(q.b.toLowerCase(),"'","")
o=B.a.V(A.T(p,'"',""))
n=o==="on"||o==="true"||o==="1"
if(!n)if(!(o==="off"||o==="false"||o==="0"))throw A.c(A.q("Expected 'ON' or 'OFF' for engine option value."))
if(m.n(B.e))m.q()
return new A.f3(r.b,n)}throw A.c(A.q("Unsupported SET statement: "+m.bS().b))},
i2(){var s,r,q=this,p=t.B
if(q.m(A.a([B.aR],p))){if(q.n(B.e))q.q()
return new A.f8()}else if(q.m(A.a([B.bX],p))){s=q.m(A.a([B.C],p))?q.j(B.d,"Expected table name.").b:null
if(q.n(B.e))q.q()
return new A.f6(s)}else if(q.m(A.a([B.aL],p))){if(!q.m(A.a([B.C],p)))q.m(A.a([B.ah],p))
r=q.j(B.d,"Expected table name after SHOW COLUMNS.")
if(q.n(B.e))q.q()
return new A.f5(r.b)}else{if(!q.m(A.a([B.aM],p)))p=q.n(B.d)&&q.a[q.b].b.toLowerCase()==="databases"
else p=!0
if(p){if(q.n(B.d))q.q()
if(q.n(B.e))q.q()
return new A.f7()}}throw A.c(A.q("Expected 'TABLES', 'INDEXES', 'COLUMNS', or 'SCHEMAS' after 'SHOW'."))},
hX(){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1=this,b2="Expected table name.",b3="Expected '(' to list columns.",b4="Expected ')' to close column list.",b5="Expected '('.",b6="Expected string literal.",b7="Expected ')'.",b8="Expected 'ON' keyword.",b9=t.B
if(b1.m(A.a([B.bo],b9))){s=b1.b
r=b1.j(B.d,"Expected trigger name.")
if(b1.m(A.a([B.bp],b9)))q="BEFORE"
else{if(!b1.m(A.a([B.bq],b9)))throw A.c(A.q("Expected 'BEFORE' or 'AFTER' trigger timing."))
q="AFTER"}if(b1.m(A.a([B.aF],b9)))p="INSERT"
else if(b1.n(B.d)&&b1.a[b1.b].b.toLowerCase()==="update"){b1.q()
p="UPDATE"}else{if(!b1.m(A.a([B.Y],b9)))throw A.c(A.q("Expected 'INSERT', 'UPDATE', or 'DELETE' trigger event."))
p="DELETE"}b1.j(B.z,"Expected 'ON' in trigger declaration.")
o=b1.j(B.d,b2)
n=b1.m(A.a([B.X],b9))
if(n){b1.j(B.br,"Expected 'EACH' after 'FOR'.")
b1.j(B.bs,"Expected 'ROW' after 'FOR EACH'.")}b1.m(A.a([B.y],b9))
m=A.a([],t.a4)
if(b1.m(A.a([B.Q],b9))){b9=b1.a
for(;;){if(!(b1.n(B.d)&&b1.e1()&&b9[b1.b].a!==B.k))break
m.push(b1.eG())}}b1.j(B.w,"Expected 'BEGIN' to start trigger body.")
l=A.a([],t.m)
b9=b1.a
for(;;){if(!(!b1.n(B.p)&&b9[b1.b].a!==B.k))break
l.push(b1.au())}b1.j(B.p,"Expected 'END' to close trigger body.")
if(b1.n(B.e))b1.q()
b9=B.b.bk(b9,s-2,b1.b)
return new A.dh(r.b,q,p,o.b,n,m,l,new A.h(b9,new A.mi(),A.z(b9).i("h<1,e>")).R(0," "))}if(b1.m(A.a([B.bd],b9))){b9=b1.b
r=b1.j(B.d,"Expected procedure name.")
k=b1.eI()
b1.j(B.y,"Expected 'AS' after procedure parameters.")
b1.j(B.w,"Expected 'BEGIN' to start procedure body.")
l=A.a([],t.m)
s=b1.a
for(;;){if(!(!b1.n(B.p)&&s[b1.b].a!==B.k))break
l.push(b1.au())}b1.j(B.p,"Expected 'END' to close procedure body.")
if(b1.n(B.e))b1.q()
b9=B.b.bk(s,b9-2,b1.b)
return new A.cB(r.b,k,l,new A.h(b9,new A.mj(),A.z(b9).i("h<1,e>")).R(0," "))}if(b1.m(A.a([B.ay],b9))){b9=b1.b
r=b1.j(B.d,"Expected function name.")
k=b1.eI()
b1.j(B.be,"Expected 'RETURNS' keyword.")
j=b1.ba()
b1.j(B.y,"Expected 'AS' after function return type.")
b1.j(B.w,"Expected 'BEGIN' to start function body.")
l=A.a([],t.m)
s=b1.a
for(;;){if(!(!b1.n(B.p)&&s[b1.b].a!==B.k))break
l.push(b1.au())}b1.j(B.p,"Expected 'END' to close function body.")
if(b1.n(B.e))b1.q()
b9=B.b.bk(s,b9-2,b1.b)
return new A.cA(r.b,k,j,l,new A.h(b9,new A.mk(),A.z(b9).i("h<1,e>")).R(0," "))}if(b1.m(A.a([B.bP],b9))||b1.aH("macro")){s=b1.j(B.d,"Expected macro name.")
k=A.a([],t.s)
if(b1.m(A.a([B.l],b9))){if(!b1.n(B.i))do k.push(b1.j(B.d,"Expected parameter name in macro.").b)
while(b1.m(A.a([B.n],b9)))
b1.j(B.i,"Expected ')' after macro parameters.")}b1.j(B.y,"Expected 'AS' after macro declaration.")
i=b1.M()
if(b1.n(B.e))b1.q()
return new A.cc(s.b,k,i)}if(b1.m(A.a([B.bQ],b9))||b1.aH("stream")){b9=b1.j(B.d,"Expected stream name.")
if(b1.n(B.e))b1.q()
return new A.eg(b9.b)}s=b1.a
if(s[b1.b].b.toLowerCase()==="database"){b1.q()
h=b1.j(B.d,"Expected database name.")
if(b1.n(B.e))b1.q()
return new A.ef(h.b)}if(b1.m(A.a([B.bz],b9))){b1.j(B.N,"Expected 'TABLE' after 'FOREIGN'.")
o=b1.j(B.d,b2)
b1.j(B.l,b3)
g=A.a([],t.bd)
do g.push(b1.dg())
while(b1.m(A.a([B.n],b9)))
b1.j(B.i,b4)
b1.j(B.bA,"Expected 'SERVER'.")
f=b1.j(B.d,"Expected server name.")
b1.j(B.bB,"Expected 'OPTIONS'.")
b1.j(B.l,"Expected '(' after 'OPTIONS'.")
s=t.N
e=A.o(s,s)
do e.k(0,b1.j(B.d,"Expected option key.").b,b1.j(B.q,"Expected string literal for option value.").b)
while(b1.m(A.a([B.n],b9)))
b1.j(B.i,"Expected ')' after options.")
if(b1.n(B.e))b1.q()
return new A.dc(o.b,g,f.b,e)}else if(b1.m(A.a([B.N],b9))){if(b1.m(A.a([B.R],b9))){d=b1.m(A.a([B.aK],b9))
if(d)b1.m(A.a([B.aN],b9))}else{d=!1
if(b1.n(B.d)&&s[b1.b].b.toLowerCase()==="if"){b1.q()
if(b1.n(B.d)&&s[b1.b].b.toLowerCase()==="not"){b1.q()
d=b1.n(B.d)&&s[b1.b].b.toLowerCase()==="exists"
if(d)b1.q()}}}o=b1.j(B.d,b2)
g=A.a([],t.bd)
if(b1.m(A.a([B.ac],b9))){b1.j(B.ae,"Expected 'OF' after 'PARTITION'.")
s=b1.j(B.d,"Expected parent table name.")
b1.j(B.X,"Expected 'FOR'.")
b1.j(B.af,"Expected 'VALUES'.")
b1.j(B.C,"Expected 'FROM'.")
b1.j(B.l,b5)
c=b1.j(B.q,b6)
b1.j(B.i,b7)
b1.j(B.O,"Expected 'TO'.")
b1.j(B.l,b5)
b=b1.j(B.q,b6)
b1.j(B.i,b7)
a=new A.hx(s.b,c.b,b.b)}else{b1.j(B.l,b3)
do g.push(b1.dg())
while(b1.m(A.a([B.n],b9)))
b1.j(B.i,b4)
a=null}if(a==null&&b1.m(A.a([B.ac],b9))){b1.j(B.T,"Expected 'BY' after 'PARTITION'.")
if(!b1.m(A.a([B.bF],b9)))throw A.c(A.q("Unsupported partitioning strategy."))
b1.j(B.l,b5)
b9=b1.j(B.d,"Expected column name.")
b1.j(B.i,b7)
a0=new A.hw(b9.b)}else a0=null
if(b1.n(B.e))b1.q()
return new A.dg(o.b,g,a0,a,d)}else if(b1.m(A.a([B.aP],b9))){a1=b1.j(B.d,"Expected relationship name.")
b1.j(B.C,"Expected 'FROM' keyword.")
a2=b1.j(B.d,"Expected source table name.")
b1.j(B.O,"Expected 'TO' keyword.")
a3=b1.j(B.d,"Expected destination table name.")
b1.j(B.z,b8)
a4=b1.j(B.d,"Expected source key column.")
b1.j(B.B,"Expected '='.")
a5=b1.j(B.d,"Expected destination key column.")
if(b1.n(B.e))b1.q()
return new A.df(a1.b,a2.b,a3.b,a4.b,a5.b)}else if(b1.m(A.a([B.aQ],b9))){if(s[b1.b].b.toLowerCase()==="if"){b1.q()
if(s[b1.b].b.toLowerCase()==="not")b1.q()
if(s[b1.b].b.toLowerCase()==="exists")b1.q()}a6=b1.j(B.d,"Expected index name.")
b1.j(B.z,b8)
o=b1.j(B.d,b2)
b1.j(B.l,"Expected '(' before column names.")
a7=A.a([],t.s)
do a7.push(A.S(b1.M()))
while(b1.m(A.a([B.n],b9)))
b1.j(B.i,"Expected ')' after column names.")
a8=B.b.R(a7,",")
if(b1.m(A.a([B.aZ],b9))){a9=s[b1.b].b.toLowerCase()
b1.q()}else a9=null
if(b1.n(B.e))b1.q()
return new A.dd(a6.b,o.b,a8,a9)}else if(b1.m(A.a([B.cn],b9))){b9=b1.j(B.d,"Expected policy name.")
b1.j(B.z,b8)
s=b1.j(B.d,b2)
b1.j(B.aZ,"Expected 'USING' keyword.")
b1.j(B.l,"Expected '(' before policy condition.")
b0=b1.M()
b1.j(B.i,"Expected ')' after policy condition.")
if(b1.n(B.e))b1.q()
return new A.de(b9.b,s.b,b0)}throw A.c(A.q("Expected 'TABLE', 'RELATIONSHIP', 'INDEX', or 'POLICY' after 'CREATE'."))},
dg(){var s,r,q,p,o,n,m,l,k,j,i,h=this,g=null,f=h.j(B.d,"Expected column name."),e=h.ba()
for(s=t.B,r=h.a,q=g,p=q,o=p,n=o,m=n,l=!1,k=!1,j=!1;;)if(h.m(A.a([B.c0],s))){h.j(B.c1,"Expected 'KEY' after 'PRIMARY'.")
l=!0}else if(h.m(A.a([B.aK],s))){if(!h.m(A.a([B.ag],s)))i=h.n(B.d)&&r[h.b].b.toLowerCase()==="null"
else i=!0
if(i)if(h.n(B.d)){i=h.b
if(r[i].a!==B.k)h.b=i+1}}else if(!h.m(A.a([B.ag],s)))if(h.m(A.a([B.c2],s)))k=!0
else if(h.m(A.a([B.c3],s))){m=h.j(B.d,"Expected referenced table name.").b
h.j(B.l,"Expected '(' before referenced column name.")
n=h.j(B.d,"Expected referenced column name.").b
h.j(B.i,"Expected ')' after referenced column name.")
if(h.m(A.a([B.z],s))){h.j(B.Y,"Expected 'DELETE' after 'ON'.")
h.j(B.c4,"Expected 'CASCADE' after 'ON DELETE'.")
j=!0}}else if(h.m(A.a([B.c8],s)))o=h.M()
else if(h.m(A.a([B.c7],s))){h.j(B.l,"Expected '(' after 'CHECK'.")
p=h.M()
h.j(B.i,"Expected ')' after CHECK expression.")}else if(h.m(A.a([B.bG],s))){h.j(B.A,"Expected 'WITH' after 'MASKED'.")
h.j(B.l,"Expected '(' after 'MASKED WITH'.")
h.j(B.ay,"Expected 'FUNCTION' in MASKED WITH clause.")
h.j(B.B,"Expected '=' after 'FUNCTION'.")
q=h.j(B.q,"Expected function name string.").b
h.j(B.i,"Expected ')' after MASKED WITH clause.")}else break
return new A.b_(f.b,e,l,k,m,n,j,o,p,q)},
hW(){var s,r,q,p,o,n,m=this,l=null
m.j(B.N,"Expected 'TABLE' after 'ALTER'.")
s=m.j(B.d,"Expected table name.").b
r=t.B
if(m.m(A.a([B.c6],r))){q=m.dg()
if(m.n(B.e))m.q()
return new A.bP(s,B.b2,q,l,l,l,l,l)}else if(m.m(A.a([B.aT],r))){m.j(B.aj,"Expected 'COLUMN' after 'DROP'.")
p=m.j(B.d,"Expected column name to drop.")
if(m.n(B.e))m.q()
return new A.bP(s,B.b3,l,p.b,l,l,l,l)}else{r=m.a
o=r[m.b].b
if(o.toLowerCase()==="rename"){m.q()
if(m.n(B.aj))m.q()
r=m.j(B.d,"Expected old column name.")
m.j(B.O,"Expected 'TO' after old column name.")
o=m.j(B.d,"Expected new column name.")
if(m.n(B.e))m.q()
return new A.bP(s,B.b4,l,l,r.b,o.b,l,l)}else if(o.toLowerCase()==="alter"){m.q()
if(m.n(B.aj))m.q()
o=m.j(B.d,"Expected target column name.")
if(r[m.b].b.toLowerCase()==="type")m.q()
n=m.ba()
if(m.n(B.e))m.q()
return new A.bP(s,B.b5,l,l,l,l,o.b,n)}else throw A.c(A.q("Expected 'ADD', 'DROP', 'RENAME', or 'ALTER' in ALTER TABLE statement."))}},
dh(a){var s,r,q,p,o,n,m,l,k,j,i,h=this,g=null
h.j(B.aH,"Expected 'INTO' keyword.")
s=h.j(B.d,"Expected table name.")
r=t.B
if(h.m(A.a([B.l],r))){q=A.a([],t.s)
do q.push(h.j(B.d,"Expected column name.").b)
while(h.m(A.a([B.n],r)))
h.j(B.i,"Expected ')' after column list.")}else q=g
h.j(B.af,"Expected 'VALUES' keyword.")
p=A.a([],t.h)
o=t.U
do{h.j(B.l,"Expected '(' to list values.")
n=A.a([],o)
do n.push(h.M())
while(h.m(A.a([B.n],r)))
h.j(B.i,"Expected ')' to close values list.")
p.push(n)}while(h.m(A.a([B.n],r)))
m=B.b.gH(p)
l=g
k=g
if(h.m(A.a([B.z],r))||h.aH("on")){if(!h.m(A.a([B.bL],r))&&!h.aH("conflict"))throw A.c(A.q("Expected 'CONFLICT' after ON."))
if(h.m(A.a([B.l],r))){l=h.j(B.d,"Expected conflict target column name.").b
h.j(B.i,"Expected ')' after conflict target column.")}if(!h.m(A.a([B.bM],r))&&!h.aH("do"))throw A.c(A.q("Expected 'DO' after ON CONFLICT."))
j=h.m(A.a([B.bN],r))||h.aH("nothing")
if(!j)if(h.aH("update")){if(!h.m(A.a([B.cT],r))&&!h.aH("set"))throw A.c(A.q("Expected 'SET' after DO UPDATE."))
k=A.o(t.N,t.k)
do{i=h.j(B.d,"Expected column name in SET clause.")
if(!h.m(A.a([B.B,B.at],r)))throw A.c(A.q("Expected '=' in SET clause."))
k.k(0,i.b,h.M())}while(h.m(A.a([B.n],r)))}else throw A.c(A.q("Expected 'NOTHING' or 'UPDATE' after DO."))}else j=!1
if(h.n(B.e))h.q()
r=p.length>1?p:g
return new A.cH(s.b,m,r,q,a,j,l,k)},
i0(){return this.dh(!1)},
bo(){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2,b3,b4,b5=this,b6=null,b7="Expected table alias.",b8=t.B
if(b5.m(A.a([B.bh],b8)))s=!0
else{s=b5.n(B.d)&&b5.a[b5.b].b.toLowerCase()==="distinct"
if(s)b5.q()}r=A.a([],t.u)
if(b5.m(A.a([B.as],b8)))r.push(new A.ai(new A.H(A.a(["*"],t.s)),b6))
else do{q=b5.M()
if(b5.m(A.a([B.y],b8)))p=b5.j(B.d,"Expected alias identifier.").b
else p=b5.n(B.d)?b5.q().b:b6
r.push(new A.ai(q,p))}while(b5.m(A.a([B.n],b8)))
o=""
n=b6
m=b6
if(b5.m(A.a([B.C],b8))){if(b5.n(B.l))l=b5.aV().a===B.v||b5.aV().a===B.A
else l=!1
if(l){b5.j(B.l,"Expected '(' before FROM subquery.")
k=b5.au()
b5.j(B.i,"Expected ')' after FROM subquery.")
if(!(k instanceof A.aS))throw A.c(A.q("Expected SelectStmt inside FROM subquery."))
n=k}else if((b5.n(B.d)||b5.n(B.P))&&b5.aV().a===B.l){j=b5.q().b
b5.j(B.l,"Expected '(' after function name.")
i=A.a([],t.U)
if(!b5.n(B.i))do i.push(b5.M())
while(b5.m(A.a([B.n],b8)))
b5.j(B.i,"Expected ')' after function arguments.")
m=new A.af(j,i)
o=j}else{h=A.a([],t.s)
l=b5.a
do if(b5.m(A.a([B.d,B.aR,B.aL,B.aM,B.aI,B.P],b8)))h.push(l[b5.b-1].b)
else if(b5.n(B.d))h.push(b5.q().b)
else throw A.c(A.q("Expected source table name."))
while(b5.m(A.a([B.J],b8)))
o=B.b.R(h,".")}}if(b5.n(B.y)&&b5.aV().a!==B.ae){b5.q()
g=b5.j(B.d,b7).b}else{l=b5.a
f=l[b5.b]
if(f.a===B.d){f=f.b
l=f.toLowerCase()!=="left"&&f.toLowerCase()!=="right"&&f.toLowerCase()!=="full"&&f.toLowerCase()!=="outer"&&!B.b.E(A.a([B.D,B.G,B.ai,B.a4,B.al,B.A,B.e,B.k],b8),l[b5.b].a)}else l=!1
g=l?b5.q().b:b6}if(b5.m(A.a([B.y],b8))){b5.j(B.ae,"Expected 'OF' after 'AS'.")
if(b5.m(A.a([B.aI],b8))){b5.j(B.aJ,"Expected TIME after SYSTEM in AS OF SYSTEM TIME.")
e=new A.e4(b5.M())}else if(b5.m(A.a([B.bE],b8)))e=new A.e4(b5.M())
else throw A.c(A.q("Expected SYSTEM TIME or TRANSACTION after AS OF."))}else e=b6
if(n!=null&&o.length===0)o=g==null?"subquery":g
d=A.a([],t.R)
for(l=b5.a;;){c=!1
b=!1
a=!1
a0=!0
if(b5.n(B.d)&&l[b5.b].b.toLowerCase()==="inner"){f=b5.b
if(l[f].a!==B.k)b5.b=f+1
b5.j(B.D,"Expected 'JOIN' after 'INNER'.")
a1=!1}else{a1=b5.n(B.d)&&l[b5.b].b.toLowerCase()==="cross"
if(a1){f=b5.b
if(l[f].a!==B.k)b5.b=f+1
b5.j(B.D,"Expected 'JOIN' after 'CROSS'.")}else{c=b5.n(B.d)&&l[b5.b].b.toLowerCase()==="left"
if(c){f=b5.b
if(l[f].a!==B.k)b5.b=f+1
if(b5.n(B.d)&&l[b5.b].b.toLowerCase()==="outer"){f=b5.b
if(l[f].a!==B.k)b5.b=f+1}b5.j(B.D,"Expected 'JOIN' after 'LEFT [OUTER]'.")}else{b=b5.n(B.d)&&l[b5.b].b.toLowerCase()==="right"
if(b){f=b5.b
if(l[f].a!==B.k)b5.b=f+1
if(b5.n(B.d)&&l[b5.b].b.toLowerCase()==="outer"){f=b5.b
if(l[f].a!==B.k)b5.b=f+1}b5.j(B.D,"Expected 'JOIN' after 'RIGHT [OUTER]'.")}else{a=b5.n(B.d)&&l[b5.b].b.toLowerCase()==="full"
if(a){f=b5.b
if(l[f].a!==B.k)b5.b=f+1
if(b5.n(B.d)&&l[b5.b].b.toLowerCase()==="outer"){f=b5.b
if(l[f].a!==B.k)b5.b=f+1}b5.j(B.D,"Expected 'JOIN' after 'FULL [OUTER]'.")}else a0=b5.m(A.a([B.D],b8))}}}}if(!a0)break
if(b5.n(B.l))f=b5.aV().a===B.v||b5.aV().a===B.A
else f=!1
if(f){b5.j(B.l,"Expected '(' before JOIN subquery.")
k=b5.au()
b5.j(B.i,"Expected ')' after JOIN subquery.")
if(!(k instanceof A.aS))throw A.c(A.q("Expected SelectStmt inside JOIN subquery."))
a2=k
a3=""}else{a3=b5.j(B.d,"Expected table to join.").b
a2=b6}if(b5.m(A.a([B.y],b8)))a4=b5.j(B.d,b7).b
else{f=l[b5.b]
if(f.a===B.d){f=f.b
f=f.toLowerCase()!=="left"&&f.toLowerCase()!=="right"&&f.toLowerCase()!=="full"&&f.toLowerCase()!=="outer"&&f.toLowerCase()!=="inner"&&f.toLowerCase()!=="cross"&&!B.b.E(A.a([B.z,B.D,B.G,B.ai,B.a4,B.al,B.A,B.e,B.k],b8),l[b5.b].a)}else f=!1
if(f){f=b5.b
a4=l[(l[f].a!==B.k?b5.b=f+1:f)-1].b}else a4=b6}if(a2!=null&&a3.length===0)a3=a4==null?"join_subquery":a4
if(a1&&!b5.m(A.a([B.z],b8)))a5=new A.ag(1)
else{b5.j(B.z,"Expected 'ON' condition for JOIN.")
a5=b5.M()}d.push(new A.br(a3,a2,a4,a5,c,b,a))}a6=b5.m(A.a([B.G],b8))?b5.M():b6
if(b5.m(A.a([B.ai],b8))){b5.j(B.T,"Expected 'BY' after 'GROUP'.")
if(b5.m(A.a([B.bv],b8))){b5.j(B.l,"Expected '(' after ROLLUP.")
i=A.a([],t.U)
do i.push(b5.M())
while(b5.m(A.a([B.n],b8)))
b5.j(B.i,"Expected ')' after ROLLUP.")
a7=new A.dO(i)}else if(b5.m(A.a([B.bw],b8))){b5.j(B.l,"Expected '(' after CUBE.")
i=A.a([],t.U)
do i.push(b5.M())
while(b5.m(A.a([B.n],b8)))
b5.j(B.i,"Expected ')' after CUBE.")
a7=new A.dj(i)}else{f=t.U
if(b5.m(A.a([B.bx],b8))){b5.j(B.by,"Expected 'SETS' after 'GROUPING'.")
b5.j(B.l,"Expected '(' after GROUPING SETS.")
a8=A.a([],t.h)
do{b5.j(B.l,"Expected '(' for a grouping set.")
i=A.a([],f)
if(!b5.n(B.i))do i.push(b5.M())
while(b5.m(A.a([B.n],b8)))
b5.j(B.i,"Expected ')' to close a grouping set.")
a8.push(i)}while(b5.m(A.a([B.n],b8)))
b5.j(B.i,"Expected ')' after GROUPING SETS.")
a7=new A.cF(a8)}else{i=A.a([],f)
do i.push(b5.M())
while(b5.m(A.a([B.n],b8)))
a7=i.length===1?i[0]:new A.cF(A.a([i],t.h))}}}else a7=b6
a9=b5.m(A.a([B.c_],b8))?b5.M():b6
if(b5.m(A.a([B.a4],b8))){b5.j(B.T,"Expected 'BY' after 'ORDER'.")
q=b5.M()
if(b5.m(A.a([B.aW],b8)))b0=!0
else{f=b5.m(A.a([B.aw],b8))
b0=!f}b1=new A.dD(q,b0)}else b1=b6
b2=b6
if(b5.m(A.a([B.al],b8))){b3=A.a4(b5.j(B.a3,"Expected numeric limit.").b,b6)
if(!b5.m(A.a([B.bi],b8)))f=b5.n(B.d)&&l[b5.b].b.toLowerCase()==="offset"
else f=!0
if(f){if(l[b5.b].b.toLowerCase()==="offset")b5.q()
b2=A.a4(b5.j(B.a3,"Expected numeric offset.").b,b6)}}else b3=b6
if(b5.m(A.a([B.A],b8))){b5.j(B.aP,"Expected 'RELATIONSHIP' after 'WITH'.")
b4=b5.j(B.d,"Expected relationship name.").b}else b4=b6
if(b5.n(B.e))b5.q()
return A.p3(e,m,n,a7,a9,s,b6,d,b3,b2,b1,r,g,o,a6,b4)},
M(){var s,r,q=this,p=q.eC()
for(s=t.B,r=q.a;q.m(A.a([B.bZ],s));)p=new A.a1(r[q.b-1].b,p,q.eC())
return p},
eC(){var s,r,q=this,p=q.eF()
for(s=t.B,r=q.a;q.m(A.a([B.aS],s));)p=new A.a1(r[q.b-1].b,p,q.eF())
return p},
eF(){var s,r,q,p,o,n=this,m=n.cd(),l=t.B
if(n.m(A.a([B.bY],l))){s=n.cd()
n.j(B.aS,"Expected 'AND' after BETWEEN lower bound.")
return new A.a1("AND",new A.a1(">=",m,s),new A.a1("<=",m,n.cd()))}if(n.m(A.a([B.ah],l))){n.j(B.l,"Expected '(' after IN")
if(n.n(B.v)||n.n(B.A)){r=n.au()
n.j(B.i,"Expected ')' after subquery.")
if(r instanceof A.aS)q=new A.co(r)
else throw A.c(A.q("Expected SelectStmt inside subquery."))}else{p=A.a([],t.U)
do p.push(n.M())
while(n.m(A.a([B.n],l)))
n.j(B.i,"Expected ')' after IN list.")
q=new A.af("in_list",p)}return new A.a1("IN",m,q)}for(o=n.a;n.m(A.a([B.B,B.aV,B.cd,B.cf,B.ce,B.cg,B.bU,B.bV,B.bO],l));)m=new A.a1(o[n.b-1].b,m,n.cd())
return m},
cd(){var s,r,q=this,p=q.eH()
for(s=t.B,r=q.a;q.m(A.a([B.cb,B.ar,B.ch],s));)p=new A.a1(r[q.b-1].b,p,q.eH())
return p},
eH(){var s,r,q=this,p=q.dj()
for(s=t.B,r=q.a;q.m(A.a([B.as,B.cc,B.ci],s));)p=new A.a1(r[q.b-1].b,p,q.dj())
return p},
dj(){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4=this,a5="Expected '(' after CAST.",a6="Expected 'AS' inside CAST.",a7="Expected ')' to close CAST.",a8=t.B
if(a4.m(A.a([B.aY],a8))){s=a4.a[a4.b-1].b
if(s==="?")r=new A.aR(s,a4.c++)
else if(B.a.U(s,"$"))r=new A.aR(s,A.d4(B.a.az(s,1))-1)
else throw A.c(A.q("Unknown placeholder format: "+s))}else if(a4.m(A.a([B.ar],a8))){q=a4.dj()
r=q instanceof A.ag&&typeof q.b=="number"?new A.ag(-A.ik(q.b)):new A.a1("-",new A.ag(0),q)}else if(a4.m(A.a([B.c9],a8)))r=new A.ag(!0)
else if(a4.m(A.a([B.ca],a8)))r=new A.ag(!1)
else if(a4.m(A.a([B.ag],a8)))r=new A.ag(null)
else if(a4.m(A.a([B.a3],a8)))r=new A.ag(A.wg(a4.a[a4.b-1].b))
else if(a4.m(A.a([B.q],a8))){s=a4.a[a4.b-1].b
p=s.length
if(p>=2)if(!(B.a.U(s,"'")&&B.a.B(s,"'")))o=B.a.U(s,'"')&&B.a.B(s,'"')
else o=!0
else o=!1
r=new A.ag(o?B.a.O(s,1,p-1):s)}else if(a4.m(A.a([B.cm],a8))){n=A.a([],t.n)
if(!a4.n(B.aX))do{m=a4.m(A.a([B.ar],a8))?-1:1
n.push(m*A.cw(a4.j(B.a3,"Expected vector element double.").b))}while(a4.m(A.a([B.n],a8)))
a4.j(B.aX,"Expected ']' to close vector literal.")
r=new A.cr(n)}else if(a4.m(A.a([B.bH],a8))){a4.j(B.l,a5)
l=a4.M()
a4.j(B.y,a6)
k=a4.ba()
a4.j(B.i,a7)
r=new A.cb(l,k)}else if(a4.m(A.a([B.d,B.bt,B.aJ,B.P,B.H,B.S,B.I,B.am,B.an,B.ao,B.ap,B.a1,B.a2,B.aq,B.aO],a8))){p=a4.a
j=p[a4.b-1].b
if(j.toLowerCase()==="match"||j.toLowerCase()==="contains"){a4.j(B.l,"Expected '(' after MATCH.")
i=a4.M()
a4.j(B.n,"Expected ',' after column name in MATCH.")
h=a4.M()
a4.j(B.i,"Expected ')' after search query in MATCH.")
g=A.S(i)
r=new A.eF(g,h instanceof A.ag?J.x(h.b):A.S(h))}else if(j.toLowerCase()==="case"){f=A.a([],t.eV)
for(;;){if(!a4.n(B.ad))o=a4.n(B.d)&&p[a4.b].b.toLowerCase()==="when"
else o=!0
if(!o)break
o=a4.b
if(p[o].a!==B.k)a4.b=o+1
e=a4.M()
a4.j(B.Z,"Expected 'THEN' after WHEN condition.")
f.push(new A.dU(e,a4.M()))}if(a4.m(A.a([B.a_],a8)))d=a4.M()
else if(a4.n(B.d)&&p[a4.b].b.toLowerCase()==="else"){a4.q()
d=a4.M()}else d=null
a4.j(B.p,"Expected 'END' to close CASE expression.")
r=new A.d9(f,d)}else if(j.toLowerCase()==="cast"){a4.j(B.l,a5)
l=a4.M()
a4.j(B.y,a6)
k=a4.ba()
a4.j(B.i,a7)
r=new A.cb(l,k)}else if(a4.n(B.l)){a4.q()
p=t.U
c=A.a([],p)
if(a4.n(B.as)){a4.q()
c.push(new A.H(A.a(["*"],t.s)))}else if(!a4.n(B.i))do c.push(a4.M())
while(a4.m(A.a([B.n],a8)))
a4.j(B.i,"Expected ')' after function arguments.")
if(a4.m(A.a([B.bg],a8))){a4.j(B.l,"Expected '(' after OVER.")
b=A.a([],p)
if(a4.m(A.a([B.ac],a8))){a4.j(B.T,"Expected 'BY' after PARTITION.")
do b.push(a4.M())
while(a4.m(A.a([B.n],a8)))}if(a4.m(A.a([B.a4],a8))){a4.j(B.T,"Expected 'BY' after ORDER.")
a=a4.M()
if(a4.m(A.a([B.aW],a8)))a0=!0
else{p=a4.m(A.a([B.aw],a8))
a0=!p}a1=new A.dD(a,a0)}else a1=null
a4.j(B.i,"Expected ')' to close OVER clause.")
r=new A.bK(j,c,b,a1)}else r=new A.af(j,c)}else{a2=A.a([j],t.s)
while(a4.m(A.a([B.J],a8)))a2.push(a4.j(B.d,"Expected identifier after dot.").b)
r=new A.H(a2)}}else{if(a4.n(B.l))p=a4.aV().a===B.v||a4.aV().a===B.A
else p=!1
if(p){a4.j(B.l,"Expected '(' before subquery.")
a3=a4.au()
a4.j(B.i,"Expected ')' after subquery.")
if(a3 instanceof A.aS)r=new A.co(a3)
else throw A.c(A.q("Expected SelectStmt inside subquery."))}else{if(a4.m(A.a([B.l],a8))){l=a4.M()
a4.j(B.i,"Expected ')' after expression.")}else throw A.c(A.q("Unexpected token '"+a4.bS().b+"' in expression."))
r=l}}for(p=a4.a;;)if(a4.n(B.cj)){o=a4.b
if(p[o].a!==B.k)a4.b=o+1
r=new A.ba(r,a4.j(B.q,"Expected string literal path after JSON operator '->'.").b,!1)}else if(a4.n(B.ck)){o=a4.b
if(p[o].a!==B.k)a4.b=o+1
r=new A.ba(r,a4.j(B.q,"Expected string literal path after JSON operator '->>'.").b,!0)}else if(a4.m(A.a([B.cl],a8)))r=new A.cb(r,a4.ba())
else break
return r},
eI(){var s,r=this,q=A.a([],t.gg),p=t.B
if(r.m(A.a([B.l],p))){if(!r.n(B.i))do{s=r.j(B.d,"Expected parameter name.")
r.ba()
q.push(new A.hv(s.b))}while(r.m(A.a([B.n],p)))
r.j(B.i,"Expected ')' after parameter list.")}return q},
eE(){var s,r,q=this,p=q.j(B.d,"Expected procedure name in CALL statement.")
q.j(B.l,"Expected '(' for CALL argument list.")
s=A.a([],t.U)
if(!q.n(B.i)){r=t.B
do s.push(q.M())
while(q.m(A.a([B.n],r)))}q.j(B.i,"Expected ')' after CALL argument list.")
if(q.n(B.e))q.q()
return new A.e9(p.b,s)},
hY(){var s,r,q,p=this,o=t.B,n=p.m(A.a([B.bu],o)),m=A.o(t.N,t.z)
do{s=p.j(B.d,"Expected CTE name.")
if(p.m(A.a([B.l],o))){do p.j(B.d,"Expected column name in CTE parameter list.")
while(p.m(A.a([B.n],o)))
p.j(B.i,"Expected ')' after CTE column names.")}p.j(B.y,"Expected 'AS' after CTE name.")
p.j(B.l,"Expected '(' before CTE query.")
p.j(B.v,"Expected 'SELECT' inside CTE query.")
r=p.eJ()
p.j(B.i,"Expected ')' after CTE query.")
m.k(0,s.b.toLowerCase(),r)}while(p.m(A.a([B.n],o)))
p.j(B.v,"Expected 'SELECT' after CTE definition.")
q=p.bo()
return new A.di(m,q,n,q.a,q.b,q.c,q.d,q.e,q.f,q.r,q.w,q.x,q.y,q.z,q.Q,q.as,q.at,q.ax)},
eJ(){var s,r,q,p=this,o=p.bo(),n=p.a[p.b].a
if(n===B.aB){s=A.a([o],t.I)
r=A.a([],t.f7)
for(n=t.B;p.m(A.a([B.aB],n));){q=p.m(A.a([B.bc],n))
p.j(B.v,"Expected 'SELECT' after 'UNION'.")
s.push(p.bo())
r.push(q)}return new A.cS(s,r)}if(n===B.aC){s=A.a([o],t.I)
for(n=t.B;p.m(A.a([B.aC],n));){p.j(B.v,"Expected 'SELECT' after 'INTERSECT'.")
s.push(p.bo())}return new A.du(s)}if(n===B.aD){s=A.a([o],t.I)
for(n=t.B;p.m(A.a([B.aD],n));){p.j(B.v,"Expected 'SELECT' after 'EXCEPT'.")
s.push(p.bo())}return new A.dm(s)}return o}}
A.mi.prototype={
$1(a){if(a.a===B.q)return"'"+A.T(a.b,"'","''")+"'"
return a.b},
$S:18}
A.mj.prototype={
$1(a){if(a.a===B.q)return"'"+A.T(a.b,"'","''")+"'"
return a.b},
$S:18}
A.mk.prototype={
$1(a){if(a.a===B.q)return"'"+A.T(a.b,"'","''")+"'"
return a.b},
$S:18}
A.f.prototype={
cb(){return"TokenType."+this.b}}
A.N.prototype={
l(a){var s=this
return"Token("+s.a.l(0)+', "'+s.b+'", L:'+s.c+":"+s.d+")"}}
A.iv.prototype={
iW(a,b){return}}
A.aZ.prototype={
l(a){return"Ptr("+this.a+", "+this.b+")"}}
A.fT.prototype={
iP(a){var s,r,q,p,o,n,m=this
if(m.e===0){s=m.a
r=m.b
q=s.C(r,0).c
q===$&&A.b()
p=q.getUint16(2,!1)
s.u(r,0,!1)
if(p===0)return!0}s=m.a
r=m.b
q=s.C(r,m.e).c
q===$&&A.b()
p=q.getUint16(2,!1)
if(p===0){s.u(r,m.e,!1)
return!0}o=m.z
o===$&&A.b()
n=q.getFloat64(4+(p-1)*o,!1)
s.u(r,m.e,!1)
return a>=n},
av(){var s,r,q,p=this,o=p.a,n=p.b
if(o.a_(n).a4()===0){s=o.C(n,0).c
s===$&&A.b()
s.$flags&2&&A.i(s,9)
s.setUint8(0,2)
s.setUint8(1,1)
s.setUint16(2,0,!1)
r=p.at
r===$&&A.b()
s.setInt32(r,-1,!1)
o.u(n,0,!0)
p.e=p.d=0}else{s=o.C(n,0).c
s===$&&A.b()
r=p.ax
r===$&&A.b()
q=s.getInt32(r,!1)
if(q===0)s=0
else s=q===-1?0:q
p.d=s
o.u(n,0,!1)
p.e=p.hH()}},
hH(){var s,r,q,p,o,n,m=this,l=m.d
for(s=m.a,r=m.b;l!==-1;l=n){q=s.C(r,l).c
q===$&&A.b()
if(q.getUint8(1)===1){s.u(r,l,!1)
return l}p=q.getUint16(2,!1)
if(p===0){s.u(r,l,!1)
return l}o=m.Q
o===$&&A.b()
n=q.getInt32(o+p*4,!1)
s.u(r,l,!1)}return 0},
dq(a){var s,r,q,p,o=this
o.d=a
s=o.a
r=o.b
q=s.C(r,0).c
q===$&&A.b()
p=o.ax
p===$&&A.b()
q.$flags&2&&A.i(q,8)
q.setInt32(p,a,!1)
s.u(r,0,!0)},
aK(a,b){var s,r,q,p,o,n=t.o
n.a(a)
n.a(b)
if(this.c===1)return B.h.A(a[0],b[0])
s=a.length
r=b.length
q=s<r?s:r
for(p=0;p<q;++p){o=B.h.A(a[p],b[p])
if(o!==0)return o}return B.c.A(s,r)},
bj(a1){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a=this,a0=a.c===1
if(a0&&a.r!=null){s=t.o
r=s.a(a1)[0]
q=a.w
q.toString
if(r>=q){q=a.x
q.toString
q=r<=q}else q=!1
if(q){q=a.a
p=a.b
o=a.r
o.toString
n=q.C(p,o)
o=n.c
o===$&&A.b()
m=o.getUint16(2,!1)
l=a.aT(n,s.b(a1)?a1:A.a([r],t.n),m)
if(l<m&&o.getFloat64(4+l*8,!1)===r){a0=a.Q
a0===$&&A.b()
k=o.getInt32(a0+l*4,!1)
a0=a.as
a0===$&&A.b()
j=o.getUint16(a0+l*2,!1)
a0=a.r
a0.toString
q.u(p,a0,!1)
return new A.aZ(k,j)}s=a.r
s.toString
q.u(p,s,!1)}}i=a.d
for(s=a.a,q=a.b;;i=b){n=s.C(q,i)
p=n.c
p===$&&A.b()
o=p.getUint8(1)
m=p.getUint16(2,!1)
if(o===1){l=a.aT(n,a1,m)
if(l<m)if(a0){r=t.o.a(a1)[0]
h=p.getFloat64(4+l*8,!1)===r}else h=a.aK(a.ao(n,l),a1)===0
else h=!1
if(h){if(a0&&m>0){a.r=i
a.w=p.getFloat64(4,!1)
a.x=p.getFloat64(4+(m-1)*8,!1)}a0=a.Q
a0===$&&A.b()
k=p.getInt32(a0+l*4,!1)
a0=a.as
a0===$&&A.b()
j=p.getUint16(a0+l*2,!1)
s.u(q,i,!1)
return new A.aZ(k,j)}o=a.at
o===$&&A.b()
g=p.getInt32(o,!1)
s.u(q,i,!1)
if(g!==-1){f=s.C(q,g)
p=f.c
p===$&&A.b()
e=p.getUint16(2,!1)
d=a.aT(f,a1,e)
if(d<e)if(a0){r=t.o.a(a1)[0]
c=p.getFloat64(4+d*8,!1)===r}else c=a.aK(a.ao(f,d),a1)===0
else c=!1
if(c){if(a0&&e>0){a.r=g
a.w=p.getFloat64(4,!1)
a.x=p.getFloat64(4+(e-1)*8,!1)}a0=a.Q
a0===$&&A.b()
k=p.getInt32(a0+d*4,!1)
a0=a.as
a0===$&&A.b()
j=p.getUint16(a0+d*2,!1)
s.u(q,g,!1)
return new A.aZ(k,j)}s.u(q,g,!1)}return null}else{l=a.aT(n,a1,m)
o=a.Q
o===$&&A.b()
b=p.getInt32(o+l*4,!1)
s.u(q,i,!1)}}},
iD(a){var s,r,q,p,o,n,m,l=this,k=l.d
for(s=l.a,r=l.b;;k=m){q=s.C(r,k)
p=q.c
p===$&&A.b()
if(p.getUint8(1)===1){s.u(r,k,!1)
return k}o=l.aT(q,a,p.getUint16(2,!1))
n=l.Q
n===$&&A.b()
m=p.getInt32(n+o*4,!1)
s.u(r,k,!1)}},
cP(a,a0){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c=this,b=A.a([],t.cK)
if(a==null){s=c.d
q=c.a
p=c.b
for(;;){if(!!0){r=0
break}o=q.C(p,s).c
o===$&&A.b()
if(o.getUint8(1)===1){q.u(p,s,!1)
r=s
break}n=c.Q
n===$&&A.b()
m=o.getInt32(n,!1)
q.u(p,s,!1)
s=m}}else r=c.iD(a)
for(q=c.a,p=c.b,o=a0!=null,n=c.c===1;r!==-1;r=d){l=q.C(p,r)
k=l.c
k===$&&A.b()
j=k.getUint16(2,!1)
for(i=0;i<j;++i){if(n){h=k.getFloat64(4+i*8,!1)
if(a!=null&&h<a[0])continue
if(o&&h>a0[0]){q.u(p,r,!1)
return b}}else{g=c.ao(l,i)
if(a!=null&&c.aK(g,a)<0)continue
if(o&&c.aK(g,a0)>0){q.u(p,r,!1)
return b}}f=c.Q
f===$&&A.b()
e=k.getInt32(f+i*4,!1)
f=c.as
f===$&&A.b()
b.push(new A.aZ(e,k.getUint16(f+i*2,!1)))}f=c.at
f===$&&A.b()
d=k.getInt32(f,!1)
q.u(p,r,!1)}return b},
b4(a3,a4,a5){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2=this
a2.r=null
s=a2.e
if(s!==-1){r=a2.a
q=a2.b
p=r.C(q,s)
s=p.c
s===$&&A.b()
o=s.getUint16(2,!1)
if(o>0){s=a2.y
s===$&&A.b()
s=o<s}else s=!1
if(s)if(a2.aK(a3,a2.ao(p,o-1))>0){a2.b8(p,a3,a4,a5)
r.u(q,a2.e,!0)
return!0}r.u(q,a2.e,!1)}a2.f=!1
s=a2.a
r=a2.b
n=s.C(r,a2.d)
q=n.c
q===$&&A.b()
if(q.getUint8(1)===1){o=q.getUint16(2,!1)
m=a2.aT(n,a3,o)
if(m<o&&a2.aK(a2.ao(n,m),a3)===0)a2.f=!0
if(!a2.b8(n,a3,a4,a5)){l=s.a_(r).a4()
k=s.C(r,l)
j=k.c
j===$&&A.b()
j.$flags&2&&A.i(j,9)
j.setUint8(0,2)
j.$flags&2&&A.i(j,9)
j.setUint8(1,1)
j.$flags&2&&A.i(j,10)
j.setUint16(2,0,!1)
i=a2.at
i===$&&A.b()
h=q.getInt32(i,!1)
j.$flags&2&&A.i(j,8)
j.setInt32(i,h,!1)
q.$flags&2&&A.i(q,8)
q.setInt32(i,l,!1)
o=q.getUint16(2,!1)
g=o/2|0
for(f=g,e=0;f<o;++f){d=a2.ao(n,f)
i=a2.Q
i===$&&A.b()
c=q.getInt32(i+f*4,!1)
h=a2.as
h===$&&A.b()
b=q.getUint16(h+f*2,!1)
a2.b1(k,e,d)
j.$flags&2&&A.i(j,8)
j.setInt32(i+e*4,c,!1)
j.$flags&2&&A.i(j,10)
j.setUint16(h+e*2,b,!1);++e}j.$flags&2&&A.i(j,10)
j.setUint16(2,e,!1)
q.$flags&2&&A.i(q,10)
q.setUint16(2,g,!1)
a=a2.ao(k,0)
if(a2.aK(a3,a)>=0)a2.b8(k,a3,a4,a5)
else a2.b8(n,a3,a4,a5)
a0=l+1
a1=s.C(r,a0)
q=a1.c
q===$&&A.b()
q.$flags&2&&A.i(q,9)
q.setUint8(0,2)
q.$flags&2&&A.i(q,9)
q.setUint8(1,0)
q.$flags&2&&A.i(q,10)
q.setUint16(2,1,!1)
a2.b1(a1,0,a)
j=a2.Q
j===$&&A.b()
i=a2.d
q.$flags&2&&A.i(q,8)
q.setInt32(j,i,!1)
q.$flags&2&&A.i(q,8)
q.setInt32(j+4,l,!1)
s.u(r,a2.d,!0)
s.u(r,l,!0)
s.u(r,a0,!0)
a2.dq(a0)
a2.e=l}else s.u(r,a2.d,!0)}else{s.u(r,a2.d,!1)
a2.ew(a2.d,a3,a4,a5)}return!a2.f},
ew(b1,b2,b3,b4){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5=this,a6=null,a7=a5.a,a8=a5.b,a9=a7.C(a8,b1),b0=a9.c
b0===$&&A.b()
s=b0.getUint8(1)
r=b0.getUint16(2,!1)
if(s===1){q=a5.aT(a9,b2,r)
if(q<r&&a5.aK(a5.ao(a9,q),b2)===0)a5.f=!0
if(a5.b8(a9,b2,b3,b4)){a7.u(a8,b1,!0)
return a6}p=a7.a_(a8).a4()
o=a7.C(a8,p)
s=o.c
s===$&&A.b()
s.$flags&2&&A.i(s,9)
s.setUint8(0,2)
s.$flags&2&&A.i(s,9)
s.setUint8(1,1)
s.$flags&2&&A.i(s,10)
s.setUint16(2,0,!1)
n=a5.at
n===$&&A.b()
m=b0.getInt32(n,!1)
s.$flags&2&&A.i(s,8)
s.setInt32(n,m,!1)
b0.$flags&2&&A.i(b0,8)
b0.setInt32(n,p,!1)
l=r/2|0
for(k=l,j=0;k<r;++k){i=a5.ao(a9,k)
n=a5.Q
n===$&&A.b()
h=b0.getInt32(n+k*4,!1)
m=a5.as
m===$&&A.b()
g=b0.getUint16(m+k*2,!1)
a5.b1(o,j,i)
s.$flags&2&&A.i(s,8)
s.setInt32(n+j*4,h,!1)
s.$flags&2&&A.i(s,10)
s.setUint16(m+j*2,g,!1);++j}s.$flags&2&&A.i(s,10)
s.setUint16(2,j,!1)
b0.$flags&2&&A.i(b0,10)
b0.setUint16(2,l,!1)
f=a5.ao(o,0)
if(a5.aK(b2,f)>=0)a5.b8(o,b2,b3,b4)
else a5.b8(a9,b2,b3,b4)
a7.u(a8,b1,!0)
a7.u(a8,p,!0)
a5.e=p
return new A.fV(f,p)}else{q=a5.aT(a9,b2,r)
s=a5.Q
s===$&&A.b()
e=b0.getInt32(s+q*4,!1)
a7.u(a8,b1,!1)
d=a5.ew(e,b2,b3,b4)
if(d==null)return a6
c=a7.C(a8,b1)
b0=d.a
n=d.b
if(a5.d6(c,b0,n)){a7.u(a8,b1,!0)
return a6}p=a7.a_(a8).a4()
o=a7.C(a8,p)
m=o.c
m===$&&A.b()
m.$flags&2&&A.i(m,9)
m.setUint8(0,2)
m.$flags&2&&A.i(m,9)
m.setUint8(1,0)
m.$flags&2&&A.i(m,10)
m.setUint16(2,0,!1)
b=c.c
b===$&&A.b()
a=b.getUint16(2,!1)
l=a/2|0
a0=a5.ao(c,l)
k=l+1
a1=b.getInt32(s+k*4,!1)
m.$flags&2&&A.i(m,8)
m.setInt32(s,a1,!1)
for(j=0;k<a;){i=a5.ao(c,k);++k
a2=b.getInt32(s+k*4,!1)
a5.b1(o,j,i);++j
m.$flags&2&&A.i(m,8)
m.setInt32(s+j*4,a2,!1)}m.$flags&2&&A.i(m,10)
m.setUint16(2,j,!1)
b.$flags&2&&A.i(b,10)
b.setUint16(2,l,!1)
if(a5.aK(b0,a0)>=0)a5.d6(o,b0,n)
else a5.d6(c,b0,n)
a7.u(a8,b1,!0)
a7.u(a8,p,!0)
if(b1===a5.d){a3=p+1
a4=a7.C(a8,a3)
b0=a4.c
b0===$&&A.b()
b0.$flags&2&&A.i(b0,9)
b0.setUint8(0,2)
b0.$flags&2&&A.i(b0,9)
b0.setUint8(1,0)
b0.$flags&2&&A.i(b0,10)
b0.setUint16(2,1,!1)
a5.b1(a4,0,a0)
b0.$flags&2&&A.i(b0,8)
b0.setInt32(s,b1,!1)
b0.$flags&2&&A.i(b0,8)
b0.setInt32(s+4,p,!1)
a7.u(a8,a3,!0)
a5.dq(a3)
return a6}return new A.fV(a0,p)}},
b8(a,b,c,d){var s,r,q,p,o,n,m=this,l=a.c
l===$&&A.b()
s=l.getUint16(2,!1)
r=m.y
r===$&&A.b()
if(s>=r)return!1
q=m.aT(a,b,s)
for(p=s;p>q;p=o){o=p-1
m.b1(a,p,m.ao(a,o))
r=m.Q
r===$&&A.b()
n=l.getInt32(r+o*4,!1)
l.$flags&2&&A.i(l,8)
l.setInt32(r+p*4,n,!1)
n=m.as
n===$&&A.b()
r=l.getUint16(n+o*2,!1)
l.$flags&2&&A.i(l,10)
l.setUint16(n+p*2,r,!1)}m.b1(a,q,b)
r=m.Q
r===$&&A.b()
l.$flags&2&&A.i(l,8)
l.setInt32(r+q*4,c,!1)
r=m.as
r===$&&A.b()
l.$flags&2&&A.i(l,10)
l.setUint16(r+q*2,d,!1)
l.$flags&2&&A.i(l,10)
l.setUint16(2,s+1,!1)
return a.d=!0},
d6(a,b,c){var s,r,q,p,o,n,m=this,l=a.c
l===$&&A.b()
s=l.getUint16(2,!1)
r=m.y
r===$&&A.b()
if(s>=r)return!1
q=m.aT(a,b,s)
for(p=s;p>q;p=o){o=p-1
m.b1(a,p,m.ao(a,o))
r=m.Q
r===$&&A.b()
n=l.getInt32(r+p*4,!1)
l.$flags&2&&A.i(l,8)
l.setInt32(r+(p+1)*4,n,!1)}m.b1(a,q,b)
r=m.Q
r===$&&A.b()
l.$flags&2&&A.i(l,8)
l.setInt32(r+(q+1)*4,c,!1)
l.$flags&2&&A.i(l,10)
l.setUint16(2,s+1,!1)
return a.d=!0},
aT(a,b,c){var s,r,q,p,o
if(this.c===1){s=b[0]
r=c-1
for(q=0;q<=r;){p=B.c.a3(q+r,2)
o=a.c
o===$&&A.b()
if(o.getFloat64(4+p*8,!1)<s)q=p+1
else r=p-1}return q}r=c-1
for(q=0;q<=r;){p=B.c.a3(q+r,2)
if(this.aK(this.ao(a,p),b)<0)q=p+1
else r=p-1}return q},
ao(a,b){var s,r,q,p=A.a([],t.n),o=this.z
o===$&&A.b()
s=4+b*o
for(o=this.c,r=0;r<o;++r){q=a.c
q===$&&A.b()
p.push(q.getFloat64(s+r*8,!1))}return p},
b1(a,b,c){var s,r,q,p,o=this.z
o===$&&A.b()
s=4+b*o
for(o=this.c,r=0;r<o;++r){q=r<c.length?c[r]:0
p=a.c
p===$&&A.b()
p.$flags&2&&A.i(p,13)
p.setFloat64(s+r*8,q,!1)}},
fm(b1,b2,b3,b4,b5){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9=this,b0=b2.length
if(b0===0)return
a9.r=null
s=A.a([],t.t)
r=a9.d
for(q=a9.a,p=a9.b;r!==-1;r=l){s.push(r)
o=q.C(p,r).c
o===$&&A.b()
if(o.getUint8(1)===1){q.u(p,r,!1)
break}n=o.getUint16(2,!1)
m=a9.Q
m===$&&A.b()
l=o.getInt32(m+n*4,!1)
q.u(p,r,!1)}if(b4===1){k=B.b.gW(s)
o=q.C(p,k).c
o===$&&A.b()
j=o.getUint16(2,!1)
i=j>0?o.getFloat64(4+(j-1)*8,!1):-1/0
for(m=b5!=null,h=o,g=!1,f=0;f<b0;++f,g=a){e=m?b5[f]:f
d=b1[e]
c=b2[e]
b=b3[e]
o=a9.y
o===$&&A.b()
a=j<o&&d>=i
if(a){h.$flags&2&&A.i(h,13)
h.setFloat64(4+j*8,d,!1)
o=a9.Q
o===$&&A.b()
h.setInt32(o+j*4,c,!1)
o=a9.as
o===$&&A.b()
h.setUint16(o+j*2,b,!1);++j
i=d
continue}h.$flags&2&&A.i(h,10)
h.setUint16(2,j,!1)
q.u(p,k,g)
a9.h1(s,d,c,b)
k=B.b.gW(s)
o=q.C(p,k).c
o===$&&A.b()
j=o.getUint16(2,!1)
i=j>0?o.getFloat64(4+(j-1)*8,!1):-1/0
h=o}h.$flags&2&&A.i(h,10)
h.setUint16(2,j,!1)
q.u(p,k,g)}else{k=B.b.gW(s)
a0=q.C(p,k)
for(o=t.n,m=b5!=null,g=!1,f=0;f<b0;++f){e=m?b5[f]:f
a1=A.a(new Array(b4),o)
for(a2=e*b4,a3=0;a3<b4;++a3)a1[a3]=b1[a2+a3]
c=b2[e]
b=b3[e]
a2=a0.c
a2===$&&A.b()
j=a2.getUint16(2,!1)
a2=a9.y
a2===$&&A.b()
if(j<a2){if(j>0){a2=a9.aK(a1,a9.ao(a0,j-1))
a4=a2>=0}else a4=!0
if(a4){a9.b8(a0,a1,c,b)
g=!0
continue}}q.u(p,k,g)
a9.b4(a1,c,b)
B.b.v(s)
a5=a9.d
for(;a5!==-1;a5=a8){s.push(a5)
a2=q.C(p,a5).c
a2===$&&A.b()
if(a2.getUint8(1)===1){q.u(p,a5,!1)
break}a6=a2.getUint16(2,!1)
a7=a9.Q
a7===$&&A.b()
a8=a2.getInt32(a7+a6*4,!1)
q.u(p,a5,!1)}k=B.b.gW(s)
a0=q.C(p,k)
g=!1}q.u(p,k,g)}if(s.length!==0)a9.e=B.b.gW(s)},
iJ(a,b,c,d){return this.fm(a,b,c,d,null)},
h1(a0,a1,a2,a3){var s,r,q,p,o,n,m,l,k,j,i,h=this,g=B.b.gW(a0),f=h.a,e=h.b,d=f.C(e,g),c=f.a_(e).a4(),b=f.C(e,c),a=b.c
a===$&&A.b()
a.$flags&2&&A.i(a,9)
a.setUint8(0,2)
a.$flags&2&&A.i(a,9)
a.setUint8(1,1)
a.$flags&2&&A.i(a,10)
a.setUint16(2,0,!1)
s=h.at
s===$&&A.b()
r=d.c
r===$&&A.b()
q=r.getInt32(s,!1)
a.$flags&2&&A.i(a,8)
a.setInt32(s,q,!1)
r.$flags&2&&A.i(r,8)
r.setInt32(s,c,!1)
p=r.getUint16(2,!1)
o=p/2|0
for(n=o,m=0;n<p;++n){l=r.getFloat64(4+n*8,!1)
s=h.Q
s===$&&A.b()
k=r.getInt32(s+n*4,!1)
q=h.as
q===$&&A.b()
j=r.getUint16(q+n*2,!1)
a.$flags&2&&A.i(a,13)
a.setFloat64(4+m*8,l,!1)
a.$flags&2&&A.i(a,8)
a.setInt32(s+m*4,k,!1)
a.$flags&2&&A.i(a,10)
a.setUint16(q+m*2,j,!1);++m}a.$flags&2&&A.i(a,10)
a.setUint16(2,m,!1)
r.$flags&2&&A.i(r,10)
r.setUint16(2,o,!1)
i=a.getFloat64(4,!1)
if(a1>=i)h.ev(b,a1,a2,a3)
else h.ev(d,a1,a2,a3)
f.u(e,g,!0)
f.u(e,c,!0)
h.eO(a0,a0.length-1,i,c)},
ev(a,b,c,d){var s,r,q,p,o,n,m,l,k=this,j=a.c
j===$&&A.b()
s=j.getUint16(2,!1)
r=s-1
for(q=0;q<=r;){p=B.c.a3(q+r,2)
if(j.getFloat64(4+p*8,!1)<b)q=p+1
else r=p-1}for(o=s;o>q;o=n){n=o-1
m=j.getFloat64(4+n*8,!1)
j.$flags&2&&A.i(j,13)
j.setFloat64(4+o*8,m,!1)
m=k.Q
m===$&&A.b()
l=j.getInt32(m+n*4,!1)
j.$flags&2&&A.i(j,8)
j.setInt32(m+o*4,l,!1)
l=k.as
l===$&&A.b()
m=j.getUint16(l+n*2,!1)
j.$flags&2&&A.i(j,10)
j.setUint16(l+o*2,m,!1)}j.$flags&2&&A.i(j,13)
j.setFloat64(4+q*8,b,!1)
m=k.Q
m===$&&A.b()
j.$flags&2&&A.i(j,8)
j.setInt32(m+q*4,c,!1)
m=k.as
m===$&&A.b()
j.$flags&2&&A.i(j,10)
j.setUint16(m+q*2,d,!1)
j.$flags&2&&A.i(j,10)
j.setUint16(2,s+1,!1)
a.d=!0},
eO(a2,a3,a4,a5){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1=this
if(a3===0){s=a2[0]
r=a1.a
q=a1.b
p=r.a_(q).a4()
o=r.C(q,p).c
o===$&&A.b()
o.$flags&2&&A.i(o,9)
o.setUint8(0,2)
o.$flags&2&&A.i(o,9)
o.setUint8(1,0)
o.$flags&2&&A.i(o,10)
o.setUint16(2,1,!1)
o.$flags&2&&A.i(o,13)
o.setFloat64(4,a4,!1)
n=a1.Q
n===$&&A.b()
o.$flags&2&&A.i(o,8)
o.setInt32(n,s,!1)
o.$flags&2&&A.i(o,8)
o.setInt32(n+4,a5,!1)
r.u(q,p,!0)
a1.dq(p)
B.b.dB(a2,0,p)
a2[1]=a5
return}r=a3-1
m=a2[r]
q=a1.a
o=a1.b
l=q.C(o,m)
n=l.c
n===$&&A.b()
k=n.getUint16(2,!1)
j=a1.y
j===$&&A.b()
if(k<j){a1.d7(l,a4,a5)
q.u(o,m,!0)
a2[a3]=a5}else{i=q.a_(o).a4()
h=q.C(o,i)
j=h.c
j===$&&A.b()
j.$flags&2&&A.i(j,9)
j.setUint8(0,2)
j.$flags&2&&A.i(j,9)
j.setUint8(1,0)
j.$flags&2&&A.i(j,10)
j.setUint16(2,0,!1)
g=k/2|0
f=n.getFloat64(4+g*8,!1)
e=a1.Q
e===$&&A.b()
d=g+1
c=n.getInt32(e+d*4,!1)
j.$flags&2&&A.i(j,8)
j.setInt32(e,c,!1)
for(b=0;d<k;){a=n.getFloat64(4+d*8,!1);++d
a0=n.getInt32(e+d*4,!1)
j.$flags&2&&A.i(j,13)
j.setFloat64(4+b*8,a,!1);++b
j.$flags&2&&A.i(j,8)
j.setInt32(e+b*4,a0,!1)}j.$flags&2&&A.i(j,10)
j.setUint16(2,b,!1)
n.$flags&2&&A.i(n,10)
n.setUint16(2,g,!1)
if(a4>=f)a1.d7(h,a4,a5)
else a1.d7(l,a4,a5)
q.u(o,m,!0)
q.u(o,i,!0)
a2[a3]=a5
a1.eO(a2,r,f,i)}},
d7(a,b,c){var s,r,q,p,o,n,m,l,k=a.c
k===$&&A.b()
s=k.getUint16(2,!1)
r=s-1
for(q=0;q<=r;){p=B.c.a3(q+r,2)
if(k.getFloat64(4+p*8,!1)<b)q=p+1
else r=p-1}for(o=s;o>q;o=n){n=o-1
m=k.getFloat64(4+n*8,!1)
k.$flags&2&&A.i(k,13)
k.setFloat64(4+o*8,m,!1)
m=this.Q
m===$&&A.b()
l=k.getInt32(m+o*4,!1)
k.$flags&2&&A.i(k,8)
k.setInt32(m+(o+1)*4,l,!1)}k.$flags&2&&A.i(k,13)
k.setFloat64(4+q*8,b,!1)
m=this.Q
m===$&&A.b()
k.$flags&2&&A.i(k,8)
k.setInt32(m+(q+1)*4,c,!1)
k.$flags&2&&A.i(k,10)
k.setUint16(2,s+1,!1)
a.d=!0}}
A.fV.prototype={}
A.eT.prototype={
am(){return A.a7(["name",this.a,"sql",this.b],t.N,t.z)}}
A.eu.prototype={
am(){return A.a7(["name",this.a,"sql",this.b],t.N,t.z)}}
A.cR.prototype={
am(){var s=this
return A.a7(["name",s.a,"timing",s.b,"event",s.c,"tableName",s.d,"forEachRow",s.e,"sql",s.f],t.N,t.z)}}
A.bt.prototype={
am(){return A.a7(["name",this.a,"condition",A.S(this.b)],t.N,t.z)}}
A.c4.prototype={
fS(a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,a0,a1,a2,a3,a4,a5){var s,r=this,q=r.b,p=A.z(q).i("h<1,e>")
q=A.r(new A.h(q,new A.mU(),p),p.i("u.E"))
r.dx!==$&&A.bd()
r.dx=q
p=A.o(t.N,t.S)
for(s=0;s<q.length;++s)p.k(0,q[s],s)
r.fx!==$&&A.bd()
r.fx=p
q=B.b.b2(r.r,new A.mV())
r.dy!==$&&A.bd()
r.dy=q
q=B.b.b2(r.e,new A.mW())||B.b.b2(r.f,new A.mX())
r.fr!==$&&A.bd()
r.fr=q},
am(){var s,r,q,p=this,o=p.c,n=A.z(o).i("h<1,l>")
o=A.r(new A.h(o,new A.mY(),n),n.i("u.E"))
n=p.y
s=A.z(n).i("h<1,e?>")
n=A.r(new A.h(n,new A.mZ(),s),s.i("u.E"))
s=p.z
r=A.z(s).i("h<1,e?>")
s=A.r(new A.h(s,new A.n_(),r),r.i("u.E"))
r=p.Q
q=A.z(r).i("h<1,w<e,@>>")
r=A.r(new A.h(r,new A.n0(),q),q.i("u.E"))
return A.a7(["name",p.a,"columnNames",p.b,"columnTypes",o,"isColumnar",p.d,"isForeign",p.at,"foreignServer",p.ax,"foreignOptions",p.ay,"columnPrimaryKey",p.e,"columnUnique",p.f,"columnReferencesTable",p.r,"columnReferencesColumn",p.w,"columnOnDeleteCascade",p.x,"columnDefaultValues",n,"columnCheckExpressions",s,"policies",r,"partitionByColumn",p.ch,"partitionOfParent",p.CW,"partitionFromValue",p.cx,"partitionToValue",p.cy,"partitionChildren",p.db],t.N,t.z)}}
A.mU.prototype={
$1(a){return a.toLowerCase()},
$S:7}
A.mV.prototype={
$1(a){return a!=null},
$S:101}
A.mW.prototype={
$1(a){return a},
$S:38}
A.mX.prototype={
$1(a){return a},
$S:38}
A.mY.prototype={
$1(a){return a.a},
$S:103}
A.mZ.prototype={
$1(a){return a!=null?A.S(a):null},
$S:36}
A.n_.prototype={
$1(a){return a!=null?A.S(a):null},
$S:36}
A.n0.prototype={
$1(a){return a.am()},
$S:105}
A.mQ.prototype={
$1(a){if(a==null)return null
return new A.c1(new A.c_(A.il(a)).bu()).M()},
$S:35}
A.mR.prototype={
$1(a){if(a==null)return null
return new A.c1(new A.c_(A.il(a)).bu()).M()},
$S:35}
A.mS.prototype={
$1(a){return B.cH[a]},
$S:107}
A.mT.prototype={
$1(a){var s=new A.c1(new A.c_(a.h(0,"condition")).bu()).M()
return new A.bt(a.h(0,"name"),s)},
$S:108}
A.dM.prototype={
am(){var s=this
return A.a7(["name",s.a,"fromTable",s.b,"toTable",s.c,"fromKey",s.d,"toKey",s.e],t.N,t.z)}}
A.b9.prototype={
am(){var s=this
return A.a7(["name",s.a,"tableName",s.b,"columnName",s.c,"usingMethod",s.d],t.N,t.z)}}
A.iw.prototype={
cL(a,b,c){var s=this.z,r=A.E(s).i("b1<2>"),q=r.i("aJ<F.E>")
s=A.r(new A.aJ(new A.b1(s,r),new A.iB(a.toLowerCase(),b.toUpperCase(),c.toUpperCase()),q),q.i("F.E"))
return s},
fG(a,b,c){var s=c.toLowerCase(),r=this.w.I(a.toLowerCase(),new A.iC()).I(b.toLowerCase(),new A.iD()),q=J.X(r)
if(!q.E(r,s))q.T(r,s)
this.aE()},
c0(a,b,c){var s,r,q,p=a.toLowerCase()
if(p==="admin"||p==="sa")return!0
s=this.w.h(0,p)
if(s==null)return!1
r=s.h(0,b.toLowerCase())
if(r==null)return!1
q=J.X(r)
return q.E(r,c.toLowerCase())||q.E(r,"all")},
dP(){var s=this,r=t.N
return A.a7(["tables",A.Z(s.c,r,t.eT),"relationships",A.Z(s.d,r,t.fM),"indexes",A.Z(s.e,r,t._),"stats",s.f.dG(0,new A.ix(),r,t.h2),"procedures",A.Z(s.x,r,t.eO),"functions",A.Z(s.y,r,t.d5),"triggers",A.Z(s.z,r,t.f6)],r,t.z)},
dL(a){var s=this,r="relationships",q="procedures",p="functions",o="triggers"
s.r.v(0)
s.c.v(0)
if(a.h(0,"tables")!=null)t.f.a(a.h(0,"tables")).a0(0,new A.iE(s))
s.d.v(0)
if(a.h(0,r)!=null)t.f.a(a.h(0,r)).a0(0,new A.iF(s))
s.e.v(0)
if(a.h(0,"indexes")!=null)t.f.a(a.h(0,"indexes")).a0(0,new A.iG(s))
s.f.v(0)
if(a.h(0,"stats")!=null)t.f.a(a.h(0,"stats")).a0(0,new A.iH(s))
s.x.v(0)
if(a.h(0,q)!=null)t.f.a(a.h(0,q)).a0(0,new A.iI(s))
s.y.v(0)
if(a.h(0,p)!=null)t.f.a(a.h(0,p)).a0(0,new A.iJ(s))
s.z.v(0)
if(a.h(0,o)!=null)t.f.a(a.h(0,o)).a0(0,new A.iK(s))},
bg(a){return this.f.I(a.toLowerCase(),new A.iA())},
bp(a,b){this.c.k(0,a.a.toLowerCase(),a)
if(b)this.aE()},
f5(a,b){this.e.k(0,a.a.toLowerCase(),a)
this.r.v(0)
if(b)this.aE()},
bf(a){var s=a.toLowerCase()
return this.r.I(s,new A.iz(this,s))},
b5(a,b){var s,r,q=a.toLowerCase(),p=b.toLowerCase()
for(s=this.e,s=new A.ao(s,s.r,s.e,A.E(s).i("ao<2>"));s.p();){r=s.d
if(r.b.toLowerCase()===q&&r.c.toLowerCase()===p)return r}return null},
dF(){var s=0,r=A.b6(t.H),q
var $async$dF=A.b7(function(a,b){if(a===1)return A.b3(b,r)
for(;;)switch(s){case 0:s=1
break
case 1:return A.b4(q,r)}})
return A.b5($async$dF,r)},
aE(){return}}
A.iB.prototype={
$1(a){return a.d.toLowerCase()===this.a&&a.b.toUpperCase()===this.b&&a.c.toUpperCase()===this.c},
$S:109}
A.iC.prototype={
$0(){return A.o(t.N,t.dy)},
$S:110}
A.iD.prototype={
$0(){return A.a([],t.s)},
$S:111}
A.ix.prototype={
$2(a,b){return new A.aj(a,A.qp(b.am()),t.aS)},
$S:112}
A.iE.prototype={
$2(a,b){if(b instanceof A.c4)this.a.c.k(0,J.x(a),b)
else if(t.f.b(b))this.a.c.k(0,J.x(a),A.tU(A.Z(b,t.N,t.z)))},
$S:4}
A.iF.prototype={
$2(a,b){if(b instanceof A.dM)this.a.d.k(0,J.x(a),b)
else if(t.f.b(b))this.a.d.k(0,J.x(a),A.tN(A.Z(b,t.N,t.z)))},
$S:4}
A.iG.prototype={
$2(a,b){if(b instanceof A.b9)this.a.e.k(0,J.x(a),b)
else if(t.f.b(b))this.a.e.k(0,J.x(a),A.tl(A.Z(b,t.N,t.z)))},
$S:4}
A.iH.prototype={
$2(a,b){if(b instanceof A.bu)this.a.f.k(0,J.x(a),b)
else if(t.f.b(b))this.a.f.k(0,J.x(a),A.qp(A.Z(b,t.N,t.z)))},
$S:4}
A.iI.prototype={
$2(a,b){if(b instanceof A.eT)this.a.x.k(0,J.x(a),b)
else if(t.f.b(b))this.a.x.k(0,J.x(a),A.tI(A.Z(b,t.N,t.z)))},
$S:4}
A.iJ.prototype={
$2(a,b){if(b instanceof A.eu)this.a.y.k(0,J.x(a),b)
else if(t.f.b(b))this.a.y.k(0,J.x(a),A.tf(A.Z(b,t.N,t.z)))},
$S:4}
A.iK.prototype={
$2(a,b){if(b instanceof A.cR)this.a.z.k(0,J.x(a),b)
else if(t.f.b(b))this.a.z.k(0,J.x(a),A.tV(A.Z(b,t.N,t.z)))},
$S:4}
A.iA.prototype={
$0(){return A.qo(0)},
$S:113}
A.iz.prototype={
$0(){var s=this.a.e,r=A.E(s).i("b1<2>"),q=r.i("aJ<F.E>")
s=A.r(new A.aJ(new A.b1(s,r),new A.iy(this.b),q),q.i("F.E"))
return s},
$S:114}
A.iy.prototype={
$1(a){return a.b.toLowerCase()===this.a},
$S:115}
A.bs.prototype={
am(){return A.a7(["min",this.a,"max",this.b,"distinctCount",this.c],t.N,t.z)}}
A.db.prototype={
it(a){var s=this.a
if(s.length===0)return 0.05
if(a<B.b.gH(s))return 0.01
if(a>B.b.gW(this.a))return 0.01
return 1/this.a.length},
am(){return A.a7(["buckets",this.a],t.N,t.z)}}
A.bu.prototype={
am(){var s=t.N,r=t.a
return A.a7(["rowCount",this.a,"columnStats",this.b.dG(0,new A.n3(),s,r),"histograms",this.c.dG(0,new A.n4(),s,r)],s,t.z)}}
A.n3.prototype={
$2(a,b){return new A.aj(a,b.am(),t.aw)},
$S:116}
A.n4.prototype={
$2(a,b){return new A.aj(a,A.a7(["buckets",b.a],t.N,t.z),t.aw)},
$S:117}
A.n1.prototype={
$2(a,b){var s=b.h(0,"min"),r=b.h(0,"max"),q=b.h(0,"distinctCount")
if(q==null)q=0
this.a.b.k(0,a,new A.bs(s,r,q))},
$S:34}
A.n2.prototype={
$2(a,b){var s,r,q=b.h(0,"buckets")
if(q==null)q=[]
s=t.i
q=A.a6(q,!0,s)
r=new A.db(A.a([],t.n))
r.a=A.a6(q,!0,s)
this.a.c.k(0,a,r)},
$S:34}
A.bH.prototype={
am(){return A.a7(["p",this.a,"s",this.b],t.N,t.z)}}
A.h9.prototype={
av(){B.a.U(this.a,":memory:")
return},
bh(){B.a.U(this.a,":memory:")
return},
ir(a,b,c){var s,r,q,p,o,n=A.rj(a)
for(s=n.length,r=this.b,q=0;q<n.length;n.length===s||(0,A.n)(n),++q){p=r.I(n[q],new A.j4())
o=J.bc(p)
if(!o.b2(p,new A.j5(b,c)))o.T(p,new A.bH(b,c))}this.bh()},
bj(a){var s,r,q,p,o,n,m=A.rj(a),l=m.length
if(l===0)return A.a([],t.x)
for(s=this.b,r=t.ec,q=null,p=0;p<m.length;m.length===l||(0,A.n)(m),++p){o=s.h(0,m[p])
if(o==null||J.pF(o))return A.a([],t.x)
if(q==null)q=A.a6(o,!0,r)
else{n=A.z(q).i("aJ<1>")
q=A.r(new A.aJ(q,new A.j7(o),n),n.i("F.E"))}}return q==null?A.a([],t.x):q}}
A.j4.prototype={
$0(){return A.a([],t.x)},
$S:119}
A.j5.prototype={
$1(a){return a.a===this.a&&a.b===this.b},
$S:27}
A.j7.prototype={
$1(a){return J.rN(this.a,new A.j6(a))},
$S:27}
A.j6.prototype={
$1(a){var s=this.a
return a.a===s.a&&a.b===s.b},
$S:27}
A.cG.prototype={
am(){var s=this
return A.a7(["id",s.a,"vector",s.b.a,"pageId",s.c,"slotId",s.d,"neighbors",s.e],t.N,t.z)}}
A.js.prototype={
av(){B.a.U(this.a,":memory:")
return},
bh(){B.a.U(this.a,":memory:")
return},
bv(a,b){switch(this.w.toLowerCase()){case"cosine":return a.cm(b)
case"dot":return a.cp(b)
case"euclidean":default:return a.co(b)}},
b4(a0,a1,a2){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d=this,c=d.x,b=c.length,a=d.Q.fn()
if(a===0)a=1e-7
s=B.h.dz(-Math.log(a)*d.f)
r=s+1
q=J.dv(r,t.bW)
for(p=t.t,o=0;o<r;++o)q[o]=A.a([],p)
c.push(new A.cG(b,a0,a1,a2,q))
n=d.y
if(n==null){d.y=b
d.z=s
return}m=d.z
for(l=m;l>s;--l)n=d.eY(a0,n,l)
k=s<m?s:m
j=A.a([n],p)
for(l=k;l>=0;--l,j=i){i=d.ic(a0,j,64,l)
h=d.ie(a0,i,l===0?32:16)
for(p=h.length,g=0;g<h.length;h.length===p||(0,A.n)(h),++g){f=h[g]
e=c[f]
J.ae(q[l],f)
J.ae(e.e[l],b)}}if(s>d.z){d.y=b
d.z=s}},
eY(a,b,c){var s,r,q,p,o,n=this.x,m=this.bv(n[b].b,a)
for(s=b,r=!0;r;){q=n[s].e
r=!1
if(c<q.length)for(q=J.as(q[c]);q.p();){p=q.gD()
o=this.bv(n[p].b,a)
if(o<m){m=o
s=p
r=!0}}}return s},
eX(a,a0,a1,a2,a3){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d=A.q7(a0,t.S),c=t.g5,b=A.a([],c)
for(s=a0.length,r=this.x,q=0;q<a0.length;a0.length===s||(0,A.n)(a0),++q){p=a0[q]
b.push(new A.ay(p,this.bv(r[p].b,a)))}B.b.aq(b,new A.jt())
o=A.a([],c)
for(c=b.length,s=a3!=null,q=0;q<b.length;b.length===c||(0,A.n)(b),++q){n=b[q]
m=r[n.a]
if(!s||a3.$2(m.c,m.d))o.push(n)}while(b.length!==0){l=B.b.aN(b,0)
if(o.length!==0){k=B.b.gW(o)
if(o.length>=a1&&l.b>k.b)break}c=r[l.a].e
if(a2<c.length)for(c=J.as(c[a2]);c.p();){j=c.gD()
if(!d.E(0,j)){d.T(0,j)
i=this.bv(r[j].b,a)
if(o.length===0||i<B.b.gW(o).b||o.length<a1){h=new A.ay(j,i)
g=B.b.c1(b,new A.ju(i))
if(g===-1)b.push(h)
else B.b.dB(b,g,h)
f=r[j]
if(!s||a3.$2(f.c,f.d)){e=B.b.c1(o,new A.jv(i))
if(e===-1)o.push(h)
else B.b.dB(o,e,h)
if(o.length>a1)o.pop()}}}}}d=t.cw
d=A.r(new A.h(o,new A.jw(),d),d.i("u.E"))
return d},
ic(a,b,c,d){return this.eX(a,b,c,d,null)},
ie(a,b,c){var s,r,q
if(b.length<=c)return b
s=A.z(b).i("h<1,ay>")
r=A.r(new A.h(b,new A.jx(this,a),s),s.i("u.E"))
B.b.aq(r,new A.jy())
s=A.hK(r,0,A.cv(c,"count",t.S),A.z(r).c)
q=s.$ti.i("h<u.E,l>")
s=A.r(new A.h(s,new A.jz(),q),q.i("u.E"))
return s},
cO(a,b,c){var s,r,q,p,o,n,m,l=this
if(l.x.length===0||l.y==null)return A.a([],t.ae)
s=l.y
s.toString
r=l.z
for(q=r,p=s;q>0;--q)p=l.eY(a,p,q)
s=A.a([p],t.t)
o=l.eX(a,s,32>b?32:b,0,c)
s=A.z(o).i("h<1,ay>")
n=A.r(new A.h(o,new A.jA(l,a),s),s.i("u.E"))
B.b.aq(n,new A.jB())
s=A.hK(n,0,A.cv(b,"count",t.S),A.z(n).c)
m=s.$ti.i("h<u.E,cG>")
s=A.r(new A.h(s,new A.jC(l),m),m.i("u.E"))
return s}}
A.jt.prototype={
$2(a,b){return B.h.A(a.b,b.b)},
$S:26}
A.ju.prototype={
$1(a){return a.b>this.a},
$S:57}
A.jv.prototype={
$1(a){return a.b>this.a},
$S:57}
A.jw.prototype={
$1(a){return a.a},
$S:55}
A.jx.prototype={
$1(a){var s=this.a
return new A.ay(a,s.bv(s.x[a].b,this.b))},
$S:47}
A.jy.prototype={
$2(a,b){return B.h.A(a.b,b.b)},
$S:26}
A.jz.prototype={
$1(a){return a.a},
$S:55}
A.jA.prototype={
$1(a){var s=this.a
return new A.ay(a,s.bv(s.x[a].b,this.b))},
$S:47}
A.jB.prototype={
$2(a,b){return B.h.A(a.b,b.b)},
$S:26}
A.jC.prototype={
$1(a){return this.a.x[a.a]},
$S:125}
A.ay.prototype={}
A.bq.prototype={
am(){return A.a7(["vector",this.a.a,"pageId",this.b,"slotId",this.c],t.N,t.z)}}
A.hh.prototype={
av(){B.a.U(this.a,":memory:")
return},
jb(){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4=this,a5=a4.w,a6=a5.length
if(a6===0)return
s=a4.d
a6=s>a6?a6:s
if(a6<1)a6=1
r=new A.i8()
r.dU(42)
q=A.a6(a5,!0,t.b1)
B.b.fM(q,r)
p=a4.f
B.b.v(p)
for(o=0;o<a6;++o)p.push(q[o].a)
for(n=t.i,m=t.G,l=t.bF,k=0;k<10;++k){j=A.a(new Array(a6),l)
for(i=0;i<a6;++i)j[i]=A.a([],m)
for(h=a5.length,g=0;g<a5.length;a5.length===h||(0,A.n)(a5),++g){for(f=a5[g].a,e=0,d=1/0,o=0;o<a6;++o){c=a4.bA(f,p[o])
if(c<d){d=c
e=o}}j[e].push(f)}for(o=0;o<a6;++o){h=j[o]
if(h.length!==0){b=J.O(B.b.gH(h).a)
a=A.a9(b,0,!1,n)
for(h=j[o],f=h.length,g=0;g<h.length;h.length===f||(0,A.n)(h),++g)for(a0=h[g].a,a1=J.X(a0),a2=0;a2<b;++a2)a[a2]=a[a2]+a1.h(a0,a2)
for(a2=0;a2<b;++a2)a[a2]=a[a2]/j[o].length
p[o]=new A.a5(a)}else p[o]=a5[r.cA(a5.length)].a}}n=a4.r
n.v(0)
for(m=t.D,o=0;o<a6;++o)n.k(0,o,A.a([],m))
for(m=a5.length,g=0;g<a5.length;a5.length===m||(0,A.n)(a5),++g){a3=a5[g]
for(l=a3.a,e=0,d=1/0,o=0;o<a6;++o){c=a4.bA(l,p[o])
if(c<d){d=c
e=o}}l=n.h(0,e)
l.toString
J.ae(l,a3)}B.b.v(a5)},
bh(){if(this.w.length!==0)this.jb()
B.a.U(this.a,":memory:")
return},
bA(a,b){switch(this.c.toLowerCase()){case"cosine":return a.cm(b)
case"dot":return a.cp(b)
case"euclidean":default:return a.co(b)}},
b4(a,b,c){var s,r,q,p,o=this,n=new A.bq(a,b,c),m=o.f
if(m.length===0)o.w.push(n)
else{for(s=0,r=1/0,q=0;q<m.length;++q){p=o.bA(a,m[q])
if(p<r){r=p
s=q}}J.ae(o.r.I(s,new A.kV()),n)}},
cO(a,b,c){var s,r,q,p,o,n,m,l,k,j,i,h,g,f=this,e="count",d=f.f
if(d.length===0){s=A.a([],t.bo)
for(d=f.w,r=d.length,q=c!=null,p=0;p<d.length;d.length===r||(0,A.n)(d),++p){o=d[p]
if(!q||c.$2(o.b,o.c))s.push(new A.bv(o,f.bA(o.a,a)))}B.b.aq(s,new A.kW())
d=A.hK(s,0,A.cv(b,e,t.S),t.fj)
r=d.$ti.i("h<u.E,bq>")
d=A.r(new A.h(d,new A.kX(),r),r.i("u.E"))
return d}n=A.a([],t.cg)
for(m=0;m<d.length;++m)n.push(new A.bE(m,f.bA(d[m],a)))
B.b.aq(n,new A.kY())
d=t.S
r=A.hK(n,0,A.cv(f.e,e,d),t.cY)
q=r.$ti.i("h<u.E,l>")
l=A.r(new A.h(r,new A.kZ(),q),q.i("u.E"))
k=A.a([],t.bo)
for(r=l.length,q=f.r,j=c!=null,p=0;p<l.length;l.length===r||(0,A.n)(l),++p){i=q.h(0,l[p])
if(i!=null)for(h=J.as(i);h.p();){g=h.gD()
if(!j||c.$2(g.b,g.c))k.push(new A.bv(g,f.bA(g.a,a)))}}B.b.aq(k,new A.l_())
d=A.hK(k,0,A.cv(b,e,d),t.fj)
r=d.$ti.i("h<u.E,bq>")
d=A.r(new A.h(d,new A.l0(),r),r.i("u.E"))
return d}}
A.kV.prototype={
$0(){return A.a([],t.D)},
$S:126}
A.kW.prototype={
$2(a,b){return B.h.A(a.b,b.b)},
$S:43}
A.kX.prototype={
$1(a){return a.a},
$S:37}
A.kY.prototype={
$2(a,b){return B.h.A(a.b,b.b)},
$S:129}
A.kZ.prototype={
$1(a){return a.a},
$S:130}
A.l_.prototype={
$2(a,b){return B.h.A(a.b,b.b)},
$S:43}
A.l0.prototype={
$1(a){return a.a},
$S:37}
A.bv.prototype={}
A.bE.prototype={}
A.mI.prototype={
$1(a){return a.al()},
$S:131}
A.mJ.prototype={
$2(a,b){return a+b.length},
$S:132}
A.ck.prototype={
dQ(){var s=this,r=s.f
return r==null?s.f=s.a.be(s.c+"/"+s.b+".db"):r},
bD(){var s,r,q=this
if(q.r!=null){s=q.a
r=q.c+"/"+q.b+".db"
s.iV(r,q.w)
s.u(r,q.w,!0)
q.r=null
q.w=-1
if(s.gab()==null){s=s.gaI()
if(s!=null)s.c_()}}q.f=null},
iI(a){var s,r,q,p,o,n,m,l,k=this
if(k.r!=null){k.a.bs(k.c+"/"+k.b+".db",k.w)
s=k.r
s.toString
if(A.cP(s,a,a.length)){k.r.d=!0
return}k.bD()}r=k.dQ()
if(r===0){s=k.a
q=k.c+"/"+k.b+".db"
p=s.C(q,0)
s.bs(q,0)
A.f9(p)
A.cP(p,a,a.length)
p.d=!0
k.r=p
k.w=0
k.f=1
return}o=r-1
s=k.a
q=k.c+"/"+k.b+".db"
n=s.C(q,o)
s.bs(q,o)
m=a.length
if(A.cP(n,a,m)){n.d=!0
k.r=n
k.w=o}else{s.u(q,o,!1)
l=s.C(q,r)
s.bs(q,r)
A.f9(l)
A.cP(l,a,m)
l.d=!0
k.r=l
k.w=r
k.f=r+1}},
dC(a,b){var s,r,q,p,o,n,m=this,l=$.ox(),k=m.d
k===$&&A.b()
s=A.tM(l,a,b,0,0,k)
if(m.r!=null){m.a.bs(m.c+"/"+m.b+".db",m.w)
k=m.r
k.toString
if(A.cP(k,l,s)){l=m.r
l.d=!0
l=A.aT(l)
return new A.aZ(m.w,l-1)}m.bD()}r=m.dQ()
if(r===0){k=m.a
q=m.c+"/"+m.b+".db"
p=k.C(q,0)
k.bs(q,0)
A.f9(p)
A.cP(p,l,s)
p.d=!0
m.r=p
m.w=0
m.f=1
return new A.aZ(0,0)}o=r-1
k=m.a
q=m.c+"/"+m.b+".db"
p=k.C(q,o)
k.bs(q,o)
if(A.cP(p,l,s)){p.d=!0
l=A.aT(p)
m.r=p
m.w=o
return new A.aZ(o,l-1)}else{k.u(q,o,!1)
n=k.C(q,r)
A.f9(n)
A.cP(n,l,s)
n.d=!0
l=A.aT(n)
m.r=n
m.w=r
m.f=r+1
return new A.aZ(r,l-1)}},
cn(a,b,c){var s,r,q,p,o,n,m=this.a,l=this.c+"/"+this.b+".db",k=m.C(l,a),j=A.ab(k,b)
if(j!=null)try{s=A.aW(j)
r=new A.ci(s.a,c,s.c,s.d)
q=5+b*4
o=k.c
o===$&&A.b()
p=o.getUint16(q,!1)
B.j.aj(k.b,p,r.al())
m.u(l,a,!0)}catch(n){m.u(l,a,!1)}else m.u(l,a,!1)},
c3(a,b,c,d,e,f){var s,r,q,p,o=this
o.bD()
s=o.a
r=o.c+"/"+o.b+".db"
q=s.be(r)
p=f==null?s.ax:f
return new A.hF(s,r,q,p,c,a==null?B.u:a,e,o,d,b)},
fI(){var s=null
return this.c3(s,s,0,s,s,s)},
fK(a,b,c,d){return this.c3(a,null,b,c,null,d)},
fJ(a){var s=null
return this.c3(s,s,0,a,s,s)},
ed(a,b,c,a0){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d
if(b.length===0)return B.cI
s=A.at(a,0,null)
r=s.getUint16(0,!1)
q=a0==null?r:a0
if(c!=null&&c.length===q){B.b.bC(c,0,q,new A.d())
p=c}else p=A.a9(q,new A.d(),!1,t.r)
for(o=b.length,n=p.$flags|0,m=a.length,l=0;l<b.length;b.length===o||(0,A.n)(b),++l){k=b[l]
if(k<r){j=s.getUint16(2+k*2,!1)
i=k+1
h=(i<r?s.getUint16(2+i*2,!1):m)-j
if(h>0){g=s.getUint8(j)
if(g===6){f=s.getUint32(j+1,!1)
e=s.getUint32(j+5,!1)
i=this.d
i===$&&A.b()
d=i.cE(f,e)
i=new A.cZ(!1).bJ(d,0,null,!0)
n&2&&A.i(p)
p[k]=new A.m(i)}else if(g===7){f=s.getUint32(j+1,!1)
e=s.getUint32(j+5,!1)
i=this.d
i===$&&A.b()
d=i.cE(f,e)
n&2&&A.i(p)
p[k]=new A.M(null,d)}else{i=A.bT(s,j,h)
n&2&&A.i(p)
p[k]=i}}}else if(k<q){n&2&&A.i(p)
p[k]=new A.d()}}return p}}
A.hF.prototype={
gJ(a){return this},
gD(){var s=this.ax
s.toString
return s},
p(){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2=this
for(q=a2.c,p=a2.a,o=a2.b,n=a2.d,m=a2.e,l=a2.f,k=a2.y,j=k!=null,i=a2.x,h=a2.w,g=a2.r,f=g!=null;e=a2.z,e<q;){if(a2.Q==null){e=p.C(o,e)
a2.Q=e
a2.as=A.aT(e)
a2.at=0}while(e=a2.at,e<a2.as){d=a2.Q
d.toString
a2.at=e+1
s=A.ab(d,e)
if(s!=null)if(s.length>=12){c=A.at(s,0,null)
b=c.getUint32(0,!1)
a=c.getUint32(4,!1)
if(j)if(b<=k)a0=a===0||a>k
else a0=!1
else a0=n.aC(b,a,m,l)
if(a0){r=J.bm(B.j.gai(s),s.byteOffset+12,s.length-12)
try{if(f)a2.ax=a2.ay=h.ed(r,g,a2.ay,i)
else{e=h.d
e===$&&A.b()
a2.ax=A.a0(r,i,e)}return!0}catch(a1){continue}}}else try{if(f)a2.ax=a2.ay=h.ed(s,g,a2.ay,i)
else{e=h.d
e===$&&A.b()
a2.ax=A.a0(s,i,e)}return!0}catch(a1){continue}}p.u(o,a2.z,!1)
a2.Q=null;++a2.z}a2.ax=null
return!1},
$ia2:1}
A.bQ.prototype={
iK(a){var s,r,q,p,o,n,m,l,k,j,i
for(s=a.length,r=this.a,q=this.c+"/"+this.b+".col_",p=0;p<s;++p){o=q+p
n=a[p].al()
m=r.be(o)
if(m===0){l=r.C(o,0)
A.f9(l)
A.p4(l,n)
r.u(o,0,!0)
continue}k=m-1
j=A.p4(r.C(o,k),n)
r.u(o,k,j)
if(!j){i=r.C(o,m)
A.f9(i)
A.p4(i,n)
r.u(o,m,!0)}}},
cN(a){return new A.ct(this.fH(a),t.fC)},
fH(a){var s=this
return function(){var r=a
var q=0,p=1,o=[],n,m,l,k,j,i,h,g
return function $async$cN(b,c,d){if(c===1){o.push(d)
q=p}for(;;)switch(q){case 0:i=s.c+"/"+s.b+".col_"+r
h=s.a
g=h.be(i)
n=0
case 2:if(!(n<g)){q=4
break}m=h.C(i,n)
l=A.aT(m)
k=0
case 5:if(!(k<l)){q=7
break}j=A.ab(m,k)
q=j!=null?8:9
break
case 8:q=10
return b.b=A.bT(A.at(j,0,null),0,j.length),1
case 10:case 9:case 6:++k
q=5
break
case 7:h.u(i,n,!1)
case 3:++n
q=2
break
case 4:return 0
case 1:return b.c=o.at(-1),3}}}}}
A.fg.prototype={
dO(a){var s,r,q,p,o,n,m,l=this.a,k=this.b+"/"+this.c+"_toast.db",j=l.a_(k).a4(),i=a.length
for(s=j,r=0;i>0;){q=l.C(k,s)
p=q.c
p===$&&A.b()
o=i>4090
n=o?4090:i
m=o?s+1:4294967295
p.$flags&2&&A.i(p,11)
p.setUint32(0,m,!1)
p.setUint16(4,n,!1)
B.j.aF(q.b,6,6+n,a,r)
l.u(k,s,!0)
r+=n
i-=n;++s}return j},
cE(a,b){var s,r,q,p,o,n=new Uint8Array(b),m=this.a,l=this.b+"/"+this.c+"_toast.db",k=a,j=0
for(;;){if(!(k!==4294967295&&j<b))break
s=m.C(l,k)
r=s.c
r===$&&A.b()
q=r.getUint32(0,!1)
p=r.getUint16(4,!1)
o=j+p
r=s.b
B.j.a8(n,j,o,new Uint8Array(r.subarray(6,A.pg(6,6+p,r.length))))
m.u(l,k,!1)
j=o
k=q}return n}}
A.hM.prototype={
cD(a){return this.j3(a)},
j3(a){var s=0,r=A.b6(t.hd),q,p=this,o,n
var $async$cD=A.b7(function(b,c){if(b===1)return A.b3(c,r)
for(;;)switch(s){case 0:n=p.b
n===$&&A.b()
s=3
return A.ar(n.ct(a),$async$cD)
case 3:o=c
q=new A.h3(o.a,o.b,o.c)
s=1
break
case 1:return A.b4(q,r)}})
return A.b5($async$cD,r)}}
A.h3.prototype={
gt(a){return this.b.length}}
A.oo.prototype={
$1(a){return A.tg(A.o9(a))},
$S:133}
A.ob.prototype={
$1(a){var s=J.bG(a,new A.oa(),t.N)
s=A.r(s,s.$ti.i("u.E"))
return s},
$S:134}
A.oa.prototype={
$1(a){var s
if(a instanceof A.d)s="NULL"
else{s=a.ga2()
s=s==null?null:J.x(s)
if(s==null)s="NULL"}return s},
$S:20};(function aliases(){var s=J.ch.prototype
s.fN=s.l
s=A.a3.prototype
s.dT=s.aF})();(function installTearOffs(){var s=hunkHelpers._static_2,r=hunkHelpers._static_0,q=hunkHelpers._static_1,p=hunkHelpers.installStaticTearOff,o=hunkHelpers._instance_0i,n=hunkHelpers._instance_1u
s(J,"v8","tr",135)
r(A,"vl","tD",15)
q(A,"vJ","u_",25)
q(A,"vK","u0",25)
q(A,"vL","u1",25)
r(A,"r1","vD",2)
p(A,"vR",5,null,["$5"],["vw"],137,0)
p(A,"vW",4,null,["$1$4","$4"],["o7",function(a,b,c,d){return A.o7(a,b,c,d,t.z)}],138,0)
p(A,"vY",5,null,["$2$5","$5"],["pp",function(a,b,c,d,e){var m=t.z
return A.pp(a,b,c,d,e,m,m)}],139,0)
p(A,"vX",6,null,["$3$6","$6"],["po",function(a,b,c,d,e,f){var m=t.z
return A.po(a,b,c,d,e,f,m,m,m)}],140,0)
p(A,"vU",4,null,["$1$4","$4"],["qW",function(a,b,c,d){return A.qW(a,b,c,d,t.z)}],141,0)
p(A,"vV",4,null,["$2$4","$4"],["qX",function(a,b,c,d){var m=t.z
return A.qX(a,b,c,d,m,m)}],142,0)
p(A,"vT",4,null,["$3$4","$4"],["qV",function(a,b,c,d){var m=t.z
return A.qV(a,b,c,d,m,m,m)}],143,0)
p(A,"vP",5,null,["$5"],["vv"],144,0)
p(A,"vZ",4,null,["$4"],["o8"],145,0)
p(A,"vO",5,null,["$5"],["vu"],146,0)
p(A,"vN",5,null,["$5"],["vt"],147,0)
p(A,"vS",4,null,["$4"],["vx"],148,0)
q(A,"vM","vq",149)
p(A,"vQ",5,null,["$5"],["qU"],150,0)
q(A,"w1","uX",44)
o(A.fr.prototype,"gt","iS",77)
n(A.h0.prototype,"gfE","fF",102)
q(A,"wr","px",100)
q(A,"io","S",29)})();(function inheritance(){var s=hunkHelpers.mixin,r=hunkHelpers.inherit,q=hunkHelpers.inheritMany
r(A.A,null)
q(A.A,[A.oT,J.hf,A.f1,J.be,A.nn,A.ah,A.a3,A.mN,A.F,A.cL,A.eE,A.fl,A.eo,A.em,A.es,A.hQ,A.hL,A.fA,A.ec,A.cW,A.cl,A.cz,A.n7,A.lZ,A.en,A.fC,A.aa,A.lR,A.aL,A.ao,A.eD,A.dw,A.dW,A.hW,A.dQ,A.ie,A.nm,A.nW,A.bD,A.i4,A.nU,A.ih,A.hX,A.c8,A.aK,A.fp,A.hZ,A.dV,A.ad,A.hY,A.i2,A.ic,A.aU,A.ii,A.dX,A.ij,A.ft,A.nM,A.c7,A.fv,A.fW,A.fZ,A.nK,A.nZ,A.cZ,A.aw,A.bU,A.nr,A.ht,A.fa,A.ns,A.h8,A.aj,A.aE,A.ig,A.fc,A.cn,A.m_,A.dn,A.cD,A.dp,A.nG,A.i8,A.j_,A.fQ,A.fR,A.j0,A.dE,A.aq,A.dF,A.hu,A.hI,A.n6,A.cO,A.m0,A.lV,A.lW,A.ci,A.B,A.h0,A.jJ,A.bk,A.cs,A.i_,A.mh,A.P,A.d6,A.bC,A.mp,A.bj,A.jF,A.j2,A.k,A.y,A.b_,A.ai,A.br,A.dD,A.hT,A.h_,A.ce,A.h2,A.hv,A.dN,A.dU,A.c_,A.c1,A.N,A.iv,A.aZ,A.fT,A.fV,A.eT,A.eu,A.cR,A.bt,A.c4,A.dM,A.b9,A.iw,A.bs,A.db,A.bu,A.bH,A.h9,A.cG,A.js,A.ay,A.bq,A.hh,A.bv,A.bE,A.ck,A.bQ,A.fg,A.hM,A.h3])
q(J.hf,[J.ey,J.eA,J.ap,J.dx,J.dy,J.cI,J.cg])
q(J.ap,[J.ch,J.C,A.dB,A.eJ])
q(J.ch,[J.hB,J.cq,J.bf])
r(J.hj,A.f1)
r(J.l2,J.C)
q(J.cI,[J.ez,J.hk])
q(A.ah,[A.cJ,A.c5,A.hl,A.hP,A.hH,A.i3,A.eC,A.fS,A.bz,A.fi,A.hN,A.cm,A.fY])
r(A.dT,A.a3)
r(A.da,A.dT)
q(A.F,[A.J,A.cM,A.aJ,A.bV,A.cV,A.hV,A.id,A.ct,A.hF])
q(A.J,[A.u,A.aB,A.b1,A.an,A.cU,A.fu])
q(A.u,[A.fe,A.h,A.eY,A.i6])
r(A.ek,A.cM)
r(A.i9,A.fA)
r(A.ia,A.i9)
r(A.ee,A.ec)
q(A.cl,[A.ed,A.fB])
r(A.bR,A.ed)
q(A.cz,[A.iL,A.iM,A.n5,A.oj,A.ol,A.nj,A.ni,A.o0,A.je,A.nD,A.nq,A.nR,A.nF,A.lT,A.nI,A.iS,A.iT,A.nt,A.ja,A.m5,A.mG,A.kS,A.kq,A.jO,A.jT,A.jU,A.jV,A.jW,A.jX,A.jY,A.jZ,A.k_,A.k0,A.jP,A.jQ,A.jS,A.ka,A.kk,A.kl,A.kC,A.kK,A.kL,A.kw,A.kz,A.ky,A.ks,A.o4,A.lM,A.lb,A.la,A.lc,A.ld,A.lo,A.lz,A.lE,A.lF,A.lG,A.lH,A.lI,A.lJ,A.le,A.lf,A.lg,A.lh,A.li,A.lj,A.lk,A.ll,A.lm,A.ln,A.lp,A.lq,A.lr,A.ls,A.lt,A.lu,A.lv,A.lw,A.lx,A.ly,A.lA,A.lB,A.lC,A.l3,A.l4,A.l5,A.l6,A.l7,A.l8,A.l9,A.lD,A.lL,A.lK,A.mg,A.of,A.og,A.mL,A.mM,A.iN,A.iO,A.iP,A.jG,A.jH,A.mn,A.mo,A.jl,A.jk,A.jm,A.jj,A.ji,A.jh,A.jo,A.jp,A.lY,A.ne,A.nf,A.mK,A.o3,A.jE,A.jg,A.nb,A.mq,A.ms,A.mr,A.mF,A.mz,A.mw,A.mA,A.mB,A.mC,A.mE,A.mv,A.mu,A.mx,A.my,A.mt,A.j3,A.iW,A.iX,A.iV,A.iU,A.oh,A.mi,A.mj,A.mk,A.mU,A.mV,A.mW,A.mX,A.mY,A.mZ,A.n_,A.n0,A.mQ,A.mR,A.mS,A.mT,A.iB,A.iy,A.j5,A.j7,A.j6,A.ju,A.jv,A.jw,A.jx,A.jz,A.jA,A.jC,A.kX,A.kZ,A.l0,A.mI,A.oo,A.ob,A.oa])
q(A.iL,[A.ml,A.nk,A.nl,A.nT,A.nS,A.jd,A.nu,A.nz,A.ny,A.nw,A.nv,A.nC,A.nB,A.nA,A.np,A.no,A.nQ,A.nP,A.o6,A.nY,A.nX,A.m1,A.m4,A.m2,A.m8,A.m3,A.m7,A.iQ,A.kR,A.kT,A.kp,A.ko,A.jN,A.kB,A.kb,A.kc,A.kd,A.kg,A.kh,A.kj,A.km,A.kn,A.ke,A.kf,A.k2,A.k3,A.k4,A.k5,A.kD,A.kF,A.kG,A.kH,A.kI,A.kJ,A.jK,A.kx,A.jM,A.k1,A.jR,A.kr,A.kt,A.k8,A.k9,A.kM,A.kN,A.kP,A.kQ,A.jL,A.k6,A.k7,A.oq,A.or,A.me,A.mf,A.jn,A.jq,A.ng,A.iC,A.iD,A.iA,A.iz,A.j4,A.kV])
r(A.eM,A.c5)
q(A.n5,[A.mP,A.e8])
q(A.aa,[A.bZ,A.fs,A.i5,A.aN])
q(A.iM,[A.lN,A.ok,A.o1,A.oc,A.jf,A.nE,A.jr,A.lS,A.lU,A.nL,A.jc,A.jb,A.mc,A.md,A.ma,A.mb,A.m9,A.m6,A.ki,A.kE,A.ku,A.kv,A.kA,A.kO,A.j8,A.j9,A.jI,A.mO,A.nh,A.jD,A.l1,A.na,A.kU,A.j1,A.mD,A.ix,A.iE,A.iF,A.iG,A.iH,A.iI,A.iJ,A.iK,A.n3,A.n4,A.n1,A.n2,A.jt,A.jy,A.jB,A.kW,A.kY,A.l_,A.mJ])
q(A.eJ,[A.eG,A.dC])
q(A.dC,[A.fw,A.fy])
r(A.fx,A.fw)
r(A.cj,A.fx)
r(A.fz,A.fy)
r(A.bh,A.fz)
q(A.cj,[A.hn,A.eH])
q(A.bh,[A.ho,A.eI,A.hp,A.hq,A.hr,A.eK,A.eL])
r(A.fD,A.i3)
r(A.fn,A.fp)
r(A.fo,A.hZ)
r(A.i1,A.i2)
q(A.ii,[A.i0,A.ib])
r(A.cX,A.fB)
q(A.fW,[A.iZ,A.lO])
r(A.hm,A.eC)
q(A.fZ,[A.lQ,A.lP,A.nd,A.hR])
r(A.nJ,A.nK)
r(A.nc,A.iZ)
q(A.bz,[A.dL,A.hd])
q(A.dn,[A.fq,A.fr])
q(A.dp,[A.hy,A.hz,A.hA])
q(A.nr,[A.dS,A.av,A.d7,A.f])
q(A.P,[A.dG,A.hG,A.dR,A.hb,A.h7,A.fX,A.he,A.cE,A.dK,A.bW,A.ds,A.hs,A.dP,A.hU,A.ha,A.dA,A.hE,A.cK,A.dt,A.dr,A.hc,A.hi,A.hO,A.hg,A.h5,A.h1])
q(A.k,[A.d,A.p,A.j,A.m,A.a5,A.M,A.aP,A.aG,A.bp,A.bo,A.b0,A.a8])
q(A.y,[A.L,A.e4,A.G,A.hw,A.hx])
q(A.L,[A.ag,A.aR,A.H,A.a1,A.af,A.bK,A.cr,A.ba,A.co,A.dO,A.dj,A.cF,A.eF,A.d9,A.cb])
q(A.G,[A.hS,A.dg,A.dc,A.bP,A.cH,A.dk,A.fj,A.aS,A.cS,A.du,A.dm,A.dH,A.e6,A.ew,A.fm,A.eh,A.e7,A.eb,A.f0,A.ev,A.eZ,A.f4,A.f3,A.ef,A.fk,A.df,A.dd,A.dq,A.ep,A.d8,A.f8,A.f6,A.de,A.cB,A.cA,A.e9,A.eX,A.f2,A.f_,A.eW,A.eN,A.eq,A.ea,A.dh,A.ej,A.cC,A.f5,A.f7,A.eP,A.fh,A.ei,A.et,A.cc,A.eg,A.el])
r(A.di,A.aS)
s(A.dT,A.hQ)
s(A.fw,A.a3)
s(A.fx,A.es)
s(A.fy,A.a3)
s(A.fz,A.es)})()
var v={G:typeof self!="undefined"?self:globalThis,typeUniverse:{eC:new Map(),tR:{},eT:{},tPV:{},sEA:[]},mangledGlobalNames:{l:"int",W:"double",rd:"num",e:"String",Q:"bool",aE:"Null",t:"List",A:"Object",w:"Map",am:"JSObject"},mangledNames:{},types:["k(w<e,k>)()","k(w<e,k>)","~()","p(w<e,k>)","~(@,@)","ck()","e(l)","e(e)","Q(e)","k(k(w<e,k>))","Q(w<e,k>)","aE()","~(e,l)","Q(b_)","k(w<e,k>)(L)","l()","W(e)","t<w<e,k>>()","e(N)","e()","e(k)","k(L)","e?(b_)","w<e,l>()","~(e,c4)","~(~())","l(ay,ay)","Q(bH)","P(aS)","e(L)","d6()","d(w<e,k>)","bs()","aE(@)","~(e,@)","L?(@)","e?(L?)","bq(bv)","Q(Q)","L(L)","b8<B>()","Q(l,l)","l(w<e,k>,w<e,k>)","l(bv,bv)","@(@)","e(b_)","av(b_)","ay(l)","e(ai)","l(e?)","@()","~(A?,A?)","M(w<e,k>)","k(@)","@(e)","l(ay)","l(aZ,aZ)","Q(ay)","Q(P)","b8<~>(P)","ai(e)","Q(ce)","ce()","t<bk>()","l(bk,bk)","aE(A,aX)","bQ()","~(A,aX)","a5(w<e,k>)","~(l,@)","aE(@,aX)","~(e,L)","+condFn,thenFn(k(w<e,k>),k(w<e,k>))(dU)","~(@)","@(@,e)","~(aq,bb)","t<k(w<e,k>)>()","b8<l>()","t<w<e,k>>(t<w<e,k>>)","k(w<e,k>)(ai)","c4()","t<k(w<e,k>)>(t<L>)","t<e>(t<L>)","Q(bt)","F<e>(t<L>)","l(A?)","aE(~())","e(k(w<e,k>))","k(a2<k>)","Q(N)","Q()","fd<t<k>>()","l(br,br)","W(br)","ai(ai)","P(P)","w<e,@>(oK)","Q(@)","W(@)","e(t<L>)","@(k)","Q(e?)","cc?(e)","l(av)","Q(aq)","w<e,@>(bt)","t<aq>()","av(@)","bt(@)","Q(cR)","w<e,t<e>>()","t<e>()","aj<e,bu>(e,bu)","bu()","t<b9>()","Q(b9)","aj<e,w<e,@>>(e,bs)","aj<e,w<e,@>>(e,db)","l(aq,aq)","t<bH>()","dF()","~(aq,dE)","bb()","Q(l,bb)","l(l,l)","cG(ay)","t<bq>()","am(A,aX)","A?(A?)","l(bE,bE)","l(bE)","bb(k)","l(l,bb)","am(e)","t<e>(t<k>)","l(@,@)","aE(bf,bf)","~(I?,ak?,I,A,aX)","0^(I?,ak?,I,0^())<A?>","0^(I?,ak?,I,0^(1^),1^)<A?,A?>","0^(I?,ak?,I,0^(1^,2^),1^,2^)<A?,A?,A?>","0^()(I,ak,I,0^())<A?>","0^(1^)(I,ak,I,0^(1^))<A?,A?>","0^(1^,2^)(I,ak,I,0^(1^,2^))<A?,A?,A?>","aK?(I,ak,I,A,aX?)","~(I?,ak?,I,~())","ff(I,ak,I,bU,~())","ff(I,ak,I,bU,~(ff))","~(I,ak,I,e)","~(e)","I(I?,ak?,I,p8?,w<A?,A?>?)","t<W>(@)"],interceptorsByTag:null,leafTags:null,arrayRti:Symbol("$ti"),rttc:{"2;condFn,thenFn":(a,b)=>c=>c instanceof A.ia&&a.b(c.a)&&b.b(c.b)}}
A.uC(v.typeUniverse,JSON.parse('{"bf":"ch","hB":"ch","cq":"ch","wD":"dB","ey":{"Q":[],"ac":[]},"eA":{"aE":[],"ac":[]},"ap":{"am":[]},"ch":{"ap":[],"am":[]},"C":{"t":["1"],"ap":[],"J":["1"],"am":[],"aQ":["1"]},"hj":{"f1":[]},"l2":{"C":["1"],"t":["1"],"ap":[],"J":["1"],"am":[],"aQ":["1"]},"be":{"a2":["1"]},"cI":{"W":[]},"ez":{"W":[],"l":[],"ac":[]},"hk":{"W":[],"ac":[]},"cg":{"e":[],"aQ":["@"],"ac":[]},"cJ":{"ah":[]},"da":{"a3":["l"],"t":["l"],"J":["l"],"a3.E":"l"},"J":{"F":["1"]},"u":{"J":["1"],"F":["1"]},"fe":{"u":["1"],"J":["1"],"F":["1"],"u.E":"1","F.E":"1"},"cL":{"a2":["1"]},"cM":{"F":["2"],"F.E":"2"},"ek":{"cM":["1","2"],"J":["2"],"F":["2"],"F.E":"2"},"eE":{"a2":["2"]},"h":{"u":["2"],"J":["2"],"F":["2"],"u.E":"2","F.E":"2"},"aJ":{"F":["1"],"F.E":"1"},"fl":{"a2":["1"]},"bV":{"F":["2"],"F.E":"2"},"eo":{"a2":["2"]},"em":{"a2":["1"]},"dT":{"a3":["1"],"t":["1"],"J":["1"]},"eY":{"u":["1"],"J":["1"],"F":["1"],"u.E":"1","F.E":"1"},"ec":{"w":["1","2"]},"ee":{"ec":["1","2"],"w":["1","2"]},"cV":{"F":["1"],"F.E":"1"},"cW":{"a2":["1"]},"ed":{"cl":["1"],"c3":["1"],"J":["1"]},"bR":{"cl":["1"],"c3":["1"],"J":["1"]},"eM":{"c5":[],"ah":[]},"hl":{"ah":[]},"hP":{"ah":[]},"fC":{"aX":[]},"hH":{"ah":[]},"bZ":{"aa":["1","2"],"w":["1","2"],"aa.V":"2","aa.K":"1"},"aB":{"J":["1"],"F":["1"],"F.E":"1"},"aL":{"a2":["1"]},"b1":{"J":["1"],"F":["1"],"F.E":"1"},"ao":{"a2":["1"]},"an":{"J":["aj<1,2>"],"F":["aj<1,2>"],"F.E":"aj<1,2>"},"eD":{"a2":["aj<1,2>"]},"dW":{"eV":[],"dz":[]},"hV":{"F":["eV"],"F.E":"eV"},"hW":{"a2":["eV"]},"dQ":{"dz":[]},"id":{"F":["dz"],"F.E":"dz"},"ie":{"a2":["dz"]},"dB":{"ap":[],"am":[],"ac":[]},"eJ":{"ap":[],"am":[]},"eG":{"ap":[],"am":[],"ac":[]},"dC":{"bg":["1"],"ap":[],"am":[],"aQ":["1"]},"cj":{"a3":["W"],"t":["W"],"bg":["W"],"ap":[],"J":["W"],"am":[],"aQ":["W"]},"bh":{"a3":["l"],"t":["l"],"bg":["l"],"ap":[],"J":["l"],"am":[],"aQ":["l"]},"hn":{"cj":[],"a3":["W"],"t":["W"],"bg":["W"],"ap":[],"J":["W"],"am":[],"aQ":["W"],"ac":[],"a3.E":"W"},"eH":{"cj":[],"a3":["W"],"t":["W"],"bg":["W"],"ap":[],"J":["W"],"am":[],"aQ":["W"],"ac":[],"a3.E":"W"},"ho":{"bh":[],"a3":["l"],"t":["l"],"bg":["l"],"ap":[],"J":["l"],"am":[],"aQ":["l"],"ac":[],"a3.E":"l"},"eI":{"bh":[],"a3":["l"],"t":["l"],"bg":["l"],"ap":[],"J":["l"],"am":[],"aQ":["l"],"ac":[],"a3.E":"l"},"hp":{"bh":[],"a3":["l"],"t":["l"],"bg":["l"],"ap":[],"J":["l"],"am":[],"aQ":["l"],"ac":[],"a3.E":"l"},"hq":{"bh":[],"a3":["l"],"t":["l"],"bg":["l"],"ap":[],"J":["l"],"am":[],"aQ":["l"],"ac":[],"a3.E":"l"},"hr":{"bh":[],"a3":["l"],"t":["l"],"bg":["l"],"ap":[],"J":["l"],"am":[],"aQ":["l"],"ac":[],"a3.E":"l"},"eK":{"bh":[],"a3":["l"],"t":["l"],"bg":["l"],"ap":[],"J":["l"],"am":[],"aQ":["l"],"ac":[],"a3.E":"l"},"eL":{"bh":[],"bb":[],"a3":["l"],"t":["l"],"bg":["l"],"ap":[],"J":["l"],"am":[],"aQ":["l"],"ac":[],"a3.E":"l"},"i3":{"ah":[]},"fD":{"c5":[],"ah":[]},"aK":{"ah":[]},"c8":{"a2":["1"]},"ct":{"F":["1"],"F.E":"1"},"fp":{"fd":["1"]},"fn":{"fd":["1"]},"fo":{"hZ":["1"]},"ad":{"b8":["1"]},"ii":{"I":[]},"i0":{"I":[]},"ib":{"I":[]},"dX":{"ak":[]},"ij":{"p8":[]},"fs":{"aa":["1","2"],"w":["1","2"],"aa.V":"2","aa.K":"1"},"cU":{"J":["1"],"F":["1"],"F.E":"1"},"ft":{"a2":["1"]},"cX":{"cl":["1"],"c3":["1"],"J":["1"]},"c7":{"a2":["1"]},"a3":{"t":["1"],"J":["1"]},"aa":{"w":["1","2"]},"fu":{"J":["2"],"F":["2"],"F.E":"2"},"fv":{"a2":["2"]},"cl":{"c3":["1"],"J":["1"]},"fB":{"cl":["1"],"c3":["1"],"J":["1"]},"i5":{"aa":["e","@"],"w":["e","@"],"aa.V":"@","aa.K":"e"},"i6":{"u":["e"],"J":["e"],"F":["e"],"u.E":"e","F.E":"e"},"eC":{"ah":[]},"hm":{"ah":[]},"t":{"J":["1"]},"eV":{"dz":[]},"c3":{"J":["1"]},"fS":{"ah":[]},"c5":{"ah":[]},"bz":{"ah":[]},"dL":{"ah":[]},"hd":{"ah":[]},"fi":{"ah":[]},"hN":{"ah":[]},"cm":{"ah":[]},"fY":{"ah":[]},"ht":{"ah":[]},"fa":{"ah":[]},"ig":{"aX":[]},"fq":{"dn":[]},"fr":{"dn":[]},"to":{"t":["l"],"J":["l"]},"bb":{"t":["l"],"J":["l"]},"tY":{"t":["l"],"J":["l"]},"tm":{"t":["l"],"J":["l"]},"tW":{"t":["l"],"J":["l"]},"tn":{"t":["l"],"J":["l"]},"tX":{"t":["l"],"J":["l"]},"td":{"t":["W"],"J":["W"]},"te":{"t":["W"],"J":["W"]},"dG":{"P":[]},"hG":{"P":[]},"dR":{"P":[]},"hb":{"P":[]},"h7":{"P":[]},"fX":{"P":[]},"he":{"P":[]},"cE":{"P":[]},"dK":{"P":[]},"bW":{"P":[]},"ds":{"P":[]},"hs":{"P":[]},"dP":{"P":[]},"hU":{"P":[]},"ha":{"P":[]},"dA":{"P":[]},"hE":{"P":[]},"cK":{"P":[]},"dt":{"P":[]},"dr":{"P":[]},"hc":{"P":[]},"hi":{"P":[]},"hO":{"P":[]},"hg":{"P":[]},"h5":{"P":[]},"h1":{"P":[]},"d":{"k":[]},"p":{"k":[]},"a5":{"k":[]},"M":{"k":[]},"j":{"k":[]},"m":{"k":[]},"aN":{"aa":["e","k"],"w":["e","k"],"aa.V":"k","aa.K":"e"},"aP":{"k":[]},"aG":{"k":[]},"bp":{"k":[]},"bo":{"k":[]},"b0":{"k":[]},"a8":{"k":[]},"L":{"y":[]},"bK":{"L":[],"y":[]},"G":{"y":[]},"cH":{"G":[],"y":[]},"aS":{"G":[],"y":[]},"cc":{"G":[],"y":[]},"ag":{"L":[],"y":[]},"aR":{"L":[],"y":[]},"H":{"L":[],"y":[]},"a1":{"L":[],"y":[]},"af":{"L":[],"y":[]},"cr":{"L":[],"y":[]},"ba":{"L":[],"y":[]},"co":{"L":[],"y":[]},"dO":{"L":[],"y":[]},"dj":{"L":[],"y":[]},"cF":{"L":[],"y":[]},"e4":{"y":[]},"hS":{"G":[],"y":[]},"hw":{"y":[]},"hx":{"y":[]},"dg":{"G":[],"y":[]},"dc":{"G":[],"y":[]},"eF":{"L":[],"y":[]},"bP":{"G":[],"y":[]},"dk":{"G":[],"y":[]},"fj":{"G":[],"y":[]},"di":{"aS":[],"G":[],"y":[]},"cS":{"G":[],"y":[]},"du":{"G":[],"y":[]},"dm":{"G":[],"y":[]},"dH":{"G":[],"y":[]},"e6":{"G":[],"y":[]},"ew":{"G":[],"y":[]},"fm":{"G":[],"y":[]},"eh":{"G":[],"y":[]},"e7":{"G":[],"y":[]},"eb":{"G":[],"y":[]},"f0":{"G":[],"y":[]},"ev":{"G":[],"y":[]},"eZ":{"G":[],"y":[]},"f4":{"G":[],"y":[]},"f3":{"G":[],"y":[]},"ef":{"G":[],"y":[]},"fk":{"G":[],"y":[]},"df":{"G":[],"y":[]},"dd":{"G":[],"y":[]},"dq":{"G":[],"y":[]},"ep":{"G":[],"y":[]},"d8":{"G":[],"y":[]},"f8":{"G":[],"y":[]},"f6":{"G":[],"y":[]},"de":{"G":[],"y":[]},"cB":{"G":[],"y":[]},"cA":{"G":[],"y":[]},"e9":{"G":[],"y":[]},"eX":{"G":[],"y":[]},"f2":{"G":[],"y":[]},"f_":{"G":[],"y":[]},"eW":{"G":[],"y":[]},"eN":{"G":[],"y":[]},"eq":{"G":[],"y":[]},"ea":{"G":[],"y":[]},"dh":{"G":[],"y":[]},"d9":{"L":[],"y":[]},"cb":{"L":[],"y":[]},"ej":{"G":[],"y":[]},"cC":{"G":[],"y":[]},"f5":{"G":[],"y":[]},"f7":{"G":[],"y":[]},"eP":{"G":[],"y":[]},"fh":{"G":[],"y":[]},"ei":{"G":[],"y":[]},"et":{"G":[],"y":[]},"eg":{"G":[],"y":[]},"el":{"G":[],"y":[]},"hF":{"F":["t<k>"],"a2":["t<k>"],"F.E":"t<k>"}}'))
A.uB(v.typeUniverse,JSON.parse('{"J":1,"es":1,"hQ":1,"dT":1,"ed":1,"dC":1,"fp":1,"i2":1,"i1":1,"ic":1,"aU":1,"fB":1,"fW":2,"fZ":2}'))
var u={c:"Error handler must accept one Object or one Object and a StackTrace as arguments, and return a value of the returned future's type",g:"max must be in range 0 < max \u2264 2^32, was "}
var t=(function rtii(){var s=A.ca
return{bf:s("d6"),fr:s("fT"),el:s("a1"),bv:s("b_"),cv:s("db"),dU:s("bQ"),Z:s("bR<e>"),aW:s("cc"),q:s("av"),eM:s("j"),A:s("p"),r:s("k"),W:s("k(w<e,k>)"),gw:s("J<@>"),hd:s("h3"),Q:s("ah"),k:s("L"),fU:s("oK"),ec:s("bH"),b8:s("wC"),du:s("af"),d5:s("eu"),aM:s("B/"),_:s("b9"),de:s("cH"),b1:s("bq"),cK:s("C<aZ>"),bd:s("C<b_>"),aF:s("C<h_>"),d:s("C<av>"),K:s("C<k>"),G:s("C<a5>"),dK:s("C<h2>"),aY:s("C<ce>"),U:s("C<L>"),av:s("C<dn>"),x:s("C<bH>"),dL:s("C<b8<t<w<e,k>>>>"),ae:s("C<cG>"),f8:s("C<a2<k>>"),D:s("C<bq>"),R:s("C<br>"),F:s("C<t<k>>"),bF:s("C<t<a5>>"),h:s("C<t<L>>"),gy:s("C<t<W>>"),b:s("C<w<e,k>>"),aj:s("C<ci>"),E:s("C<aq>"),gg:s("C<hv>"),bL:s("C<P>"),dG:s("C<bt>"),u:s("C<ai>"),I:s("C<aS>"),ei:s("C<cO>"),bA:s("C<c3<bC>>"),m:s("C<G>"),s:s("C<e>"),aT:s("C<N>"),B:s("C<f>"),a4:s("C<hT>"),eV:s("C<dU>"),fu:s("C<bK>"),cg:s("C<bE>"),J:s("C<cs>"),g5:s("C<ay>"),f0:s("C<bk>"),bo:s("C<bv>"),f7:s("C<Q>"),n:s("C<W>"),gn:s("C<@>"),t:s("C<l>"),aP:s("aQ<@>"),v:s("eA"),eH:s("am"),g:s("bf"),aU:s("bg<@>"),aX:s("ap"),eb:s("t<bH>"),b0:s("t<b9>"),gB:s("t<bq>"),c:s("t<w<e,k>>"),be:s("t<aq>"),dy:s("t<e>"),aQ:s("t<bk>"),o:s("t<W>"),j:s("t<@>"),bW:s("t<l>"),fs:s("t<k(w<e,k>)>"),gV:s("ag"),aS:s("aj<e,bu>"),aw:s("aj<e,w<e,@>>"),b_:s("w<e,k>"),a:s("w<e,@>"),g6:s("w<e,l>"),f:s("w<@,@>"),dT:s("w<e,t<e>>"),e:s("h<e,e>"),dh:s("h<e,W>"),cw:s("h<ay,l>"),bq:s("h<a2<k>,k>"),dP:s("bs"),d4:s("cj"),eB:s("bh"),P:s("aE"),C:s("A"),b7:s("dE"),L:s("aq"),h0:s("hu"),d9:s("dF"),dV:s("bt"),eO:s("eT"),gY:s("ai"),V:s("B"),gT:s("wI"),bQ:s("+()"),cz:s("eV"),fM:s("dM"),bJ:s("eY<e>"),gZ:s("ck"),Y:s("bC"),fi:s("hI"),eu:s("c3<k>"),gc:s("c3<fd<e>>"),cq:s("c3<e>"),l:s("aX"),cf:s("G"),da:s("fd<t<k>>"),N:s("e"),eT:s("c4"),h2:s("bu"),dn:s("ff"),f6:s("cR"),dm:s("ac"),ch:s("dS"),eK:s("c5"),p:s("bb"),cE:s("hM"),ak:s("cq"),w:s("H"),af:s("fn<t<k>>"),cY:s("bE"),aI:s("i_"),eI:s("ad<@>"),fj:s("bv"),fC:s("ct<k>"),y:s("Q"),i:s("W"),z:s("@"),bI:s("@(A)"),ag:s("@(A,aX)"),S:s("l"),g1:s("k?"),ev:s("k(w<e,k>)?"),O:s("L?"),bG:s("b8<aE>?"),an:s("am?"),eg:s("t<l>?"),fY:s("w<e,k>?"),X:s("A?"),M:s("cO?"),T:s("e?"),fQ:s("Q?"),cD:s("W?"),h6:s("l?"),e6:s("rd?"),di:s("rd"),H:s("~")}})();(function constants(){var s=hunkHelpers.makeConstList
B.cB=J.hf.prototype
B.b=J.C.prototype
B.cC=J.ey.prototype
B.c=J.ez.prototype
B.h=J.cI.prototype
B.a=J.cg.prototype
B.cD=J.bf.prototype
B.cE=J.ap.prototype
B.r=A.eG.prototype
B.ab=A.eH.prototype
B.E=A.eI.prototype
B.j=A.eL.prototype
B.ba=J.hB.prototype
B.b1=J.cq.prototype
B.b2=new A.d7(0,"add")
B.b3=new A.d7(1,"drop")
B.b4=new A.d7(2,"renameColumn")
B.b5=new A.d7(3,"alterColumnType")
B.co=new A.em(A.ca("em<0&>"))
B.dn=new A.j_()
B.b6=function getTagFallback(o) {
  var s = Object.prototype.toString.call(o);
  return s.substring(8, s.length - 1);
}
B.cp=function() {
  var toStringFunction = Object.prototype.toString;
  function getTag(o) {
    var s = toStringFunction.call(o);
    return s.substring(8, s.length - 1);
  }
  function getUnknownTag(object, tag) {
    if (/^HTML[A-Z].*Element$/.test(tag)) {
      var name = toStringFunction.call(object);
      if (name == "[object Object]") return null;
      return "HTMLElement";
    }
  }
  function getUnknownTagGenericBrowser(object, tag) {
    if (object instanceof HTMLElement) return "HTMLElement";
    return getUnknownTag(object, tag);
  }
  function prototypeForTag(tag) {
    if (typeof window == "undefined") return null;
    if (typeof window[tag] == "undefined") return null;
    var constructor = window[tag];
    if (typeof constructor != "function") return null;
    return constructor.prototype;
  }
  function discriminator(tag) { return null; }
  var isBrowser = typeof HTMLElement == "function";
  return {
    getTag: getTag,
    getUnknownTag: isBrowser ? getUnknownTagGenericBrowser : getUnknownTag,
    prototypeForTag: prototypeForTag,
    discriminator: discriminator };
}
B.cu=function(getTagFallback) {
  return function(hooks) {
    if (typeof navigator != "object") return hooks;
    var userAgent = navigator.userAgent;
    if (typeof userAgent != "string") return hooks;
    if (userAgent.indexOf("DumpRenderTree") >= 0) return hooks;
    if (userAgent.indexOf("Chrome") >= 0) {
      function confirm(p) {
        return typeof window == "object" && window[p] && window[p].name == p;
      }
      if (confirm("Window") && confirm("HTMLElement")) return hooks;
    }
    hooks.getTag = getTagFallback;
  };
}
B.cq=function(hooks) {
  if (typeof dartExperimentalFixupGetTag != "function") return hooks;
  hooks.getTag = dartExperimentalFixupGetTag(hooks.getTag);
}
B.ct=function(hooks) {
  if (typeof navigator != "object") return hooks;
  var userAgent = navigator.userAgent;
  if (typeof userAgent != "string") return hooks;
  if (userAgent.indexOf("Firefox") == -1) return hooks;
  var getTag = hooks.getTag;
  var quickMap = {
    "BeforeUnloadEvent": "Event",
    "DataTransfer": "Clipboard",
    "GeoGeolocation": "Geolocation",
    "Location": "!Location",
    "WorkerMessageEvent": "MessageEvent",
    "XMLDocument": "!Document"};
  function getTagFirefox(o) {
    var tag = getTag(o);
    return quickMap[tag] || tag;
  }
  hooks.getTag = getTagFirefox;
}
B.cs=function(hooks) {
  if (typeof navigator != "object") return hooks;
  var userAgent = navigator.userAgent;
  if (typeof userAgent != "string") return hooks;
  if (userAgent.indexOf("Trident/") == -1) return hooks;
  var getTag = hooks.getTag;
  var quickMap = {
    "BeforeUnloadEvent": "Event",
    "DataTransfer": "Clipboard",
    "HTMLDDElement": "HTMLElement",
    "HTMLDTElement": "HTMLElement",
    "HTMLPhraseElement": "HTMLElement",
    "Position": "Geoposition"
  };
  function getTagIE(o) {
    var tag = getTag(o);
    var newTag = quickMap[tag];
    if (newTag) return newTag;
    if (tag == "Object") {
      if (window.DataView && (o instanceof window.DataView)) return "DataView";
    }
    return tag;
  }
  function prototypeForTagIE(tag) {
    var constructor = window[tag];
    if (constructor == null) return null;
    return constructor.prototype;
  }
  hooks.getTag = getTagIE;
  hooks.prototypeForTag = prototypeForTagIE;
}
B.cr=function(hooks) {
  var getTag = hooks.getTag;
  var prototypeForTag = hooks.prototypeForTag;
  function getTagFixed(o) {
    var tag = getTag(o);
    if (tag == "Document") {
      if (!!o.xmlVersion) return "!Document";
      return "!HTMLDocument";
    }
    return tag;
  }
  function prototypeForTagFixed(tag) {
    if (tag == "Document") return null;
    return prototypeForTag(tag);
  }
  hooks.getTag = getTagFixed;
  hooks.prototypeForTag = prototypeForTagFixed;
}
B.b7=function(hooks) { return hooks; }

B.o=new A.lO()
B.cv=new A.ht()
B.V=new A.mN()
B.a5=new A.nc()
B.x=new A.nd()
B.cw=new A.nG()
B.m=new A.ib()
B.av=new A.av(0,"integer")
B.L=new A.av(1,"double")
B.t=new A.av(2,"text")
B.W=new A.av(3,"vector")
B.M=new A.av(4,"json")
B.a6=new A.av(5,"boolean")
B.a7=new A.av(6,"uuid")
B.a8=new A.av(7,"datetime")
B.a9=new A.av(8,"blob")
B.aa=new A.av(9,"decimal")
B.f=new A.bU(0)
B.cx=new A.cD(0)
B.cy=new A.cD(1)
B.b8=new A.cD(2)
B.cz=new A.cD(3)
B.cA=new A.cD(4)
B.cF=new A.lP(null)
B.cG=new A.lQ(null)
B.cH=s([B.av,B.L,B.t,B.W,B.M,B.a6,B.a7,B.a8,B.a9,B.aa],t.d)
B.cI=s([],t.K)
B.cJ=s([],t.U)
B.b9=s([],t.R)
B.cN={analyze:0,explain:1,select:2,from:3,where:4,join:5,on:6,limit:7,order:8,by:9,asc:10,desc:11,create:12,table:13,insert:14,into:15,values:16,as:17,commit:18,rollback:19,relationship:20,index:21,show:22,tables:23,indexes:24,to:25,with:26,in:27,generate:28,group:29,like:30,between:31,and:32,or:33,having:34,primary:35,key:36,unique:37,references:38,delete:39,cascade:40,alter:41,add:42,drop:43,column:44,check:45,default:46,declare:47,begin:48,end:49,if:50,then:51,else:52,elsif:53,while:54,loop:55,int:56,integer:57,bigint:58,smallint:59,double:60,real:61,float:62,decimal:63,numeric:64,text:65,varchar:66,char:67,string:68,vector:69,json:70,bool:71,boolean:72,uuid:73,guid:74,datetime:75,timestamp:76,date:77,blob:78,bytea:79,bytes:80,true:81,false:82,cast:83,pragma:84,describe:85,columns:86,schemas:87,truncate:88,exists:89,ilike:90,not:91,null:92,policy:93,using:94,conflict:95,do:96,nothing:97,replace:98,macro:99,stream:100,emit:101,procedure:102,function:103,returns:104,return:105,call:106,union:107,all:108,over:109,partition:110,intersect:111,except:112,distinct:113,offset:114,savepoint:115,release:116,cursor:117,for:118,open:119,fetch:120,close:121,trigger:122,before:123,after:124,each:125,row:126,exception:127,when:128,fts:129,match:130,recursive:131,rollup:132,cube:133,grouping:134,sets:135,foreign:136,server:137,options:138,checkpoint:139,vacuum:140,full:141,of:142,system:143,time:144,transaction:145,range:146,masked:147}
B.ax=new A.f(100,"analyze")
B.bb=new A.f(0,"explain")
B.v=new A.f(1,"select")
B.C=new A.f(2,"from")
B.G=new A.f(3,"where")
B.D=new A.f(4,"join")
B.z=new A.f(5,"on")
B.al=new A.f(6,"limit")
B.a4=new A.f(7,"orderBy")
B.T=new A.f(8,"by")
B.aW=new A.f(9,"asc")
B.aw=new A.f(10,"desc")
B.bf=new A.f(11,"create")
B.N=new A.f(12,"table")
B.aF=new A.f(13,"insert")
B.aH=new A.f(14,"into")
B.af=new A.f(15,"valuesKeyword")
B.y=new A.f(16,"as")
B.bS=new A.f(17,"commit")
B.bT=new A.f(18,"rollback")
B.aP=new A.f(19,"relationship")
B.aQ=new A.f(20,"indexKeyword")
B.bW=new A.f(28,"showKeyword")
B.aR=new A.f(29,"tablesKeyword")
B.bX=new A.f(30,"indexesKeyword")
B.O=new A.f(21,"to")
B.A=new A.f(22,"withKeyword")
B.ah=new A.f(23,"inKeyword")
B.P=new A.f(24,"generate")
B.ai=new A.f(25,"groupKeyword")
B.bU=new A.f(26,"likeKeyword")
B.bY=new A.f(31,"betweenKeyword")
B.aS=new A.f(32,"andKeyword")
B.bZ=new A.f(33,"orKeyword")
B.c_=new A.f(34,"havingKeyword")
B.c0=new A.f(35,"primaryKeyword")
B.c1=new A.f(36,"keyKeyword")
B.c2=new A.f(37,"uniqueKeyword")
B.c3=new A.f(38,"referencesKeyword")
B.Y=new A.f(39,"deleteKeyword")
B.c4=new A.f(40,"cascadeKeyword")
B.c5=new A.f(41,"alterKeyword")
B.c6=new A.f(42,"addKeyword")
B.aT=new A.f(43,"dropKeyword")
B.aj=new A.f(44,"columnKeyword")
B.c7=new A.f(45,"checkKeyword")
B.c8=new A.f(46,"defaultKeyword")
B.Q=new A.f(48,"declare")
B.w=new A.f(49,"begin")
B.p=new A.f(50,"end")
B.R=new A.f(51,"ifKeyword")
B.Z=new A.f(52,"then")
B.a_=new A.f(53,"elseKeyword")
B.ak=new A.f(54,"elsif")
B.aU=new A.f(55,"whileKeyword")
B.a0=new A.f(56,"loop")
B.H=new A.f(57,"typeInt")
B.S=new A.f(58,"typeDouble")
B.aq=new A.f(66,"typeDecimal")
B.I=new A.f(59,"typeText")
B.am=new A.f(60,"typeVector")
B.an=new A.f(61,"typeJson")
B.ao=new A.f(62,"typeBool")
B.ap=new A.f(63,"typeUuid")
B.a1=new A.f(64,"typeDateTime")
B.a2=new A.f(65,"typeBlob")
B.c9=new A.f(70,"trueKeyword")
B.ca=new A.f(71,"falseKeyword")
B.bH=new A.f(153,"castKeyword")
B.bI=new A.f(154,"pragmaKeyword")
B.bJ=new A.f(155,"describeKeyword")
B.aL=new A.f(156,"columnsKeyword")
B.aM=new A.f(157,"schemasKeyword")
B.bK=new A.f(158,"truncateKeyword")
B.aN=new A.f(159,"existsKeyword")
B.bV=new A.f(27,"ilikeKeyword")
B.aK=new A.f(151,"notKeyword")
B.ag=new A.f(152,"nullKeyword")
B.cn=new A.f(98,"policyKeyword")
B.aZ=new A.f(99,"usingKeyword")
B.bL=new A.f(161,"conflictKeyword")
B.bM=new A.f(162,"doKeyword")
B.bN=new A.f(163,"nothingKeyword")
B.aO=new A.f(164,"replaceKeyword")
B.bP=new A.f(166,"macroKeyword")
B.bQ=new A.f(167,"streamKeyword")
B.bR=new A.f(168,"emitKeyword")
B.bd=new A.f(107,"procedureKeyword")
B.ay=new A.f(108,"functionKeyword")
B.be=new A.f(109,"returnsKeyword")
B.az=new A.f(110,"returnKeyword")
B.aA=new A.f(111,"callKeyword")
B.aB=new A.f(112,"union")
B.bc=new A.f(104,"all")
B.bg=new A.f(113,"over")
B.ac=new A.f(114,"partition")
B.aC=new A.f(115,"intersect")
B.aD=new A.f(116,"except")
B.bh=new A.f(117,"distinct")
B.bi=new A.f(118,"offset")
B.bj=new A.f(119,"savepointKeyword")
B.bk=new A.f(120,"releaseKeyword")
B.aE=new A.f(121,"cursorKeyword")
B.X=new A.f(122,"forKeyword")
B.bl=new A.f(123,"openKeyword")
B.bm=new A.f(124,"fetchKeyword")
B.bn=new A.f(125,"closeKeyword")
B.bo=new A.f(126,"triggerKeyword")
B.bp=new A.f(127,"beforeKeyword")
B.bq=new A.f(128,"afterKeyword")
B.br=new A.f(129,"eachKeyword")
B.bs=new A.f(130,"rowKeyword")
B.aG=new A.f(131,"exceptionKeyword")
B.ad=new A.f(132,"whenKeyword")
B.cU=new A.f(133,"ftsKeyword")
B.bt=new A.f(134,"matchKeyword")
B.bu=new A.f(135,"recursiveKeyword")
B.bv=new A.f(136,"rollupKeyword")
B.bw=new A.f(137,"cubeKeyword")
B.bx=new A.f(138,"groupingKeyword")
B.by=new A.f(139,"setsKeyword")
B.bz=new A.f(140,"foreignKeyword")
B.bA=new A.f(141,"serverKeyword")
B.bB=new A.f(142,"optionsKeyword")
B.cV=new A.f(47,"checkpointKeyword")
B.bC=new A.f(143,"vacuumKeyword")
B.bD=new A.f(144,"fullKeyword")
B.ae=new A.f(145,"ofKeyword")
B.aI=new A.f(146,"systemKeyword")
B.aJ=new A.f(147,"timeKeyword")
B.bE=new A.f(148,"transactionKeyword")
B.bF=new A.f(149,"rangeKeyword")
B.bG=new A.f(150,"maskedKeyword")
B.cK=new A.ee(B.cN,[B.ax,B.bb,B.v,B.C,B.G,B.D,B.z,B.al,B.a4,B.T,B.aW,B.aw,B.bf,B.N,B.aF,B.aH,B.af,B.y,B.bS,B.bT,B.aP,B.aQ,B.bW,B.aR,B.bX,B.O,B.A,B.ah,B.P,B.ai,B.bU,B.bY,B.aS,B.bZ,B.c_,B.c0,B.c1,B.c2,B.c3,B.Y,B.c4,B.c5,B.c6,B.aT,B.aj,B.c7,B.c8,B.Q,B.w,B.p,B.R,B.Z,B.a_,B.ak,B.aU,B.a0,B.H,B.H,B.H,B.H,B.S,B.S,B.S,B.aq,B.aq,B.I,B.I,B.I,B.I,B.am,B.an,B.ao,B.ao,B.ap,B.ap,B.a1,B.a1,B.a1,B.a2,B.a2,B.a2,B.c9,B.ca,B.bH,B.bI,B.bJ,B.aL,B.aM,B.bK,B.aN,B.bV,B.aK,B.ag,B.cn,B.aZ,B.bL,B.bM,B.bN,B.aO,B.bP,B.bQ,B.bR,B.bd,B.ay,B.be,B.az,B.aA,B.aB,B.bc,B.bg,B.ac,B.aC,B.aD,B.bh,B.bi,B.bj,B.bk,B.aE,B.X,B.bl,B.bm,B.bn,B.bo,B.bp,B.bq,B.br,B.bs,B.aG,B.ad,B.cU,B.bt,B.bu,B.bv,B.bw,B.bx,B.by,B.bz,B.bA,B.bB,B.cV,B.bC,B.bD,B.ae,B.aI,B.aJ,B.bE,B.bF,B.bG],A.ca("ee<e,f>"))
B.cM={a:0,about:1,above:2,after:3,again:4,against:5,all:6,am:7,an:8,and:9,any:10,are:11,"aren't":12,as:13,at:14,be:15,because:16,been:17,before:18,being:19,below:20,between:21,both:22,but:23,by:24,"can't":25,cannot:26,could:27,"couldn't":28,did:29,"didn't":30,do:31,does:32,"doesn't":33,doing:34,"don't":35,down:36,during:37,each:38,few:39,for:40,from:41,further:42,had:43,"hadn't":44,has:45,"hasn't":46,have:47,"haven't":48,having:49,he:50,"he'd":51,"he'll":52,"he's":53,her:54,here:55,"here's":56,hers:57,herself:58,him:59,himself:60,his:61,how:62,"how's":63,i:64,"i'd":65,"i'll":66,"i'm":67,"i've":68,if:69,in:70,into:71,is:72,"isn't":73,it:74,"it's":75,its:76,itself:77,"let's":78,me:79,more:80,most:81,"mustn't":82,my:83,myself:84,no:85,nor:86,not:87,of:88,off:89,on:90,once:91,only:92,or:93,other:94,ought:95,our:96,ours:97,ourselves:98,out:99,over:100,own:101,same:102,"shan't":103,she:104,"she'd":105,"she'll":106,"she's":107,should:108,"shouldn't":109,so:110,some:111,such:112,than:113,that:114,"that's":115,the:116,their:117,theirs:118,them:119,themselves:120,then:121,there:122,"there's":123,these:124,they:125,"they'd":126,"they'll":127,"they're":128,"they've":129,this:130,those:131,through:132,to:133,too:134,under:135,until:136,up:137,very:138,was:139,"wasn't":140,we:141,"we'd":142,"we'll":143,"we're":144,"we've":145,were:146,"weren't":147,what:148,"what's":149,when:150,"when's":151,where:152,"where's":153,which:154,while:155,who:156,"who's":157,whom:158,why:159,"why's":160,with:161,"won't":162,would:163,"wouldn't":164,you:165,"you'd":166,"you'll":167,"you're":168,"you've":169,your:170,yours:171,yourself:172,yourselves:173}
B.cQ=new A.bR(B.cM,174,t.Z)
B.cO={}
B.u=new A.bR(B.cO,0,A.ca("bR<l>"))
B.cP={int:0,integer:1,bigint:2,smallint:3,double:4,real:5,float:6,decimal:7,numeric:8,text:9,varchar:10,char:11,string:12,vector:13,json:14}
B.cR=new A.bR(B.cP,15,t.Z)
B.cL={update:0,select:1,insert:2,delete:3,create:4,show:5,grant:6,revoke:7,explain:8,analyze:9,use:10}
B.cS=new A.bR(B.cL,11,t.Z)
B.F=new A.hL("sessionTxContext")
B.cT=new A.f(105,"setKeyword")
B.bO=new A.f(165,"tilde")
B.d=new A.f(67,"identifier")
B.a3=new A.f(68,"numberLiteral")
B.q=new A.f(69,"stringLiteral")
B.cb=new A.f(72,"plus")
B.ar=new A.f(73,"minus")
B.as=new A.f(74,"asterisk")
B.cc=new A.f(75,"slash")
B.B=new A.f(76,"equals")
B.aV=new A.f(77,"notEquals")
B.cd=new A.f(78,"lessThan")
B.ce=new A.f(79,"greaterThan")
B.cf=new A.f(80,"lessThanOrEquals")
B.cg=new A.f(81,"greaterThanOrEquals")
B.at=new A.f(82,"assign")
B.ch=new A.f(83,"concat")
B.ci=new A.f(84,"modulo")
B.cj=new A.f(85,"arrow")
B.ck=new A.f(86,"arrowText")
B.cl=new A.f(87,"doubleColon")
B.l=new A.f(88,"lParen")
B.i=new A.f(89,"rParen")
B.cm=new A.f(90,"lBracket")
B.aX=new A.f(91,"rBracket")
B.n=new A.f(92,"comma")
B.e=new A.f(93,"semicolon")
B.J=new A.f(94,"dot")
B.k=new A.f(95,"eof")
B.K=new A.f(96,"invalid")
B.aY=new A.f(97,"placeholder")
B.b_=new A.dS(0,"active")
B.U=new A.dS(1,"committed")
B.b0=new A.dS(2,"aborted")
B.cW=A.bF("ws")
B.cX=A.bF("wt")
B.cY=A.bF("td")
B.cZ=A.bF("te")
B.d_=A.bF("tm")
B.d0=A.bF("tn")
B.d1=A.bF("to")
B.d2=A.bF("A")
B.d3=A.bF("tW")
B.d4=A.bF("tX")
B.d5=A.bF("tY")
B.d6=A.bF("bb")
B.d7=new A.hR(!1)
B.d8=new A.hR(!0)
B.au=new A.ig("")
B.d9=new A.aU(B.m,A.vR())
B.da=new A.aU(B.m,A.vN())
B.db=new A.aU(B.m,A.vV())
B.dc=new A.aU(B.m,A.vO())
B.dd=new A.aU(B.m,A.vP())
B.de=new A.aU(B.m,A.vQ())
B.df=new A.aU(B.m,A.vS())
B.dg=new A.aU(B.m,A.vU())
B.dh=new A.aU(B.m,A.vW())
B.di=new A.aU(B.m,A.vX())
B.dj=new A.aU(B.m,A.vY())
B.dk=new A.aU(B.m,A.vZ())
B.dl=new A.aU(B.m,A.vT())
B.dm=new A.ij(null,null,null,null,null,null,null,null,null,null,null,null,null)})();(function staticFields(){$.nH=null
$.d1=A.a([],A.ca("C<A>"))
$.qT=null
$.qe=null
$.mm=0
$.cN=A.vl()
$.pM=null
$.pL=null
$.rb=null
$.r0=null
$.ri=null
$.oe=null
$.om=null
$.pt=null
$.nN=A.a([],A.ca("C<t<A>?>"))
$.dY=null
$.fK=null
$.fL=null
$.pl=!1
$.V=B.m
$.nO=null
$.wY=A.o(t.S,A.ca("wX"))
$.cy=A.a([99,124,119,123,242,107,111,197,48,1,103,43,254,215,171,118,202,130,201,125,250,89,71,240,173,212,162,175,156,164,114,192,183,253,147,38,54,63,247,204,52,165,229,241,113,216,49,21,4,199,35,195,24,150,5,154,7,18,128,226,235,39,178,117,9,131,44,26,27,110,90,160,82,59,214,179,41,227,47,132,83,209,0,237,32,252,177,91,106,203,190,57,74,76,88,207,208,239,170,251,67,77,51,133,69,249,2,127,80,60,159,168,81,163,64,143,146,157,56,245,188,182,218,33,16,255,243,210,205,12,19,236,95,151,68,23,196,167,126,61,100,93,25,115,96,129,79,220,34,42,144,136,70,238,184,20,222,94,11,219,224,50,58,10,73,6,36,92,194,211,172,98,145,149,228,121,231,200,55,109,141,213,78,169,108,86,244,234,101,122,174,8,186,120,37,46,28,166,180,198,232,221,116,31,75,189,139,138,112,62,181,102,72,3,246,14,97,53,87,185,134,193,29,158,225,248,152,17,105,217,142,148,155,30,135,233,206,85,40,223,140,161,137,13,191,230,66,104,65,153,45,15,176,84,187,22],t.t)
$.ex=A.o(t.N,A.ca("t<y>"))
$.pY=0
$.eB=null
$.pT=A.a([],A.ca("C<oK>"))
$.oM=null
$.pS=""
$.oL=!1
$.cQ=A.a([],t.b)
$.pf=A.qv()})();(function lazyInitializers(){var s=hunkHelpers.lazyFinal,r=hunkHelpers.lazy
s($,"wv","rl",()=>A.ra("_$dart_dartClosure"))
s($,"wu","os",()=>A.ra("_$dart_dartClosure_dartJSInterop"))
s($,"wW","ov",()=>A.lX(0))
s($,"x5","rH",()=>A.a([new J.hj()],A.ca("C<f1>")))
s($,"wL","rr",()=>A.c6(A.n8({
toString:function(){return"$receiver$"}})))
s($,"wM","rs",()=>A.c6(A.n8({$method$:null,
toString:function(){return"$receiver$"}})))
s($,"wN","rt",()=>A.c6(A.n8(null)))
s($,"wO","ru",()=>A.c6(function(){var $argumentsExpr$="$arguments$"
try{null.$method$($argumentsExpr$)}catch(q){return q.message}}()))
s($,"wR","rx",()=>A.c6(A.n8(void 0)))
s($,"wS","ry",()=>A.c6(function(){var $argumentsExpr$="$arguments$"
try{(void 0).$method$($argumentsExpr$)}catch(q){return q.message}}()))
s($,"wQ","rw",()=>A.c6(A.qs(null)))
s($,"wP","rv",()=>A.c6(function(){try{null.$method$}catch(q){return q.message}}()))
s($,"wU","rA",()=>A.c6(A.qs(void 0)))
s($,"wT","rz",()=>A.c6(function(){try{(void 0).$method$}catch(q){return q.message}}()))
s($,"wV","pA",()=>A.tZ())
s($,"wZ","rB",()=>{var q=t.z
return A.pW(q,q)})
s($,"x1","rE",()=>A.lX(4096))
s($,"x_","rC",()=>new A.nY().$0())
s($,"x0","rD",()=>new A.nX().$0())
s($,"ww","rm",()=>A.aI("^([+-]?\\d{4,6})-?(\\d\\d)-?(\\d\\d)(?:[ T](\\d\\d)(?::?(\\d\\d)(?::?(\\d\\d)(?:[.,](\\d+))?)?)?( ?[zZ]| ?([-+])(\\d\\d)(?::?(\\d\\d))?)?)?$",!0))
s($,"x2","ow",()=>A.rf(B.d2))
s($,"wJ","ou",()=>{A.tF()
return $.mm})
s($,"wA","rn",()=>A.aI("^(?:\\\\\\\\|[a-zA-Z]:[/\\\\])",!0))
s($,"wB","ro",()=>$.fO()?A.aI("[^/\\\\][/\\\\]+[^/\\\\]",!0):A.aI("[^/]/+[^/]",!0))
s($,"x3","rF",()=>new A.A())
s($,"wF","rp",()=>A.ur())
s($,"wH","ot",()=>A.ut())
s($,"wG","rq",()=>A.us())
r($,"wE","fO",()=>{$.rq()
return!1})
s($,"x4","rG",()=>Symbol("jsBoxedDartObjectProperty"))
s($,"x6","pB",()=>A.lX(1048576))
s($,"wz","R",()=>A.oG(0))
s($,"wy","U",()=>A.oG(1))
s($,"wx","pz",()=>{var q,p=J.dv(1101,t.A)
for(q=0;q<1101;++q)p[q]=A.oG(q-100)
return p})
s($,"x7","ox",()=>A.lX(65536))
s($,"x8","rI",()=>A.at($.ox(),0,null))})();(function nativeSupport(){!function(){var s=function(a){var m={}
m[a]=1
return Object.keys(hunkHelpers.convertToFastObject(m))[0]}
v.getIsolateTag=function(a){return s("___dart_"+a+v.isolateTag)}
var r="___dart_isolate_tags_"
var q=Object[r]||(Object[r]=Object.create(null))
var p="_ZxYxX"
for(var o=0;;o++){var n=s(p+"_"+o+"_")
if(!(n in q)){q[n]=1
v.isolateTag=n
break}}v.dispatchPropertyName=v.getIsolateTag("dispatch_record")}()
hunkHelpers.setOrUpdateInterceptorsByTag({ArrayBuffer:A.dB,SharedArrayBuffer:A.dB,ArrayBufferView:A.eJ,DataView:A.eG,Float32Array:A.hn,Float64Array:A.eH,Int16Array:A.ho,Int32Array:A.eI,Int8Array:A.hp,Uint16Array:A.hq,Uint32Array:A.hr,Uint8ClampedArray:A.eK,CanvasPixelArray:A.eK,Uint8Array:A.eL})
hunkHelpers.setOrUpdateLeafTags({ArrayBuffer:true,SharedArrayBuffer:true,ArrayBufferView:false,DataView:true,Float32Array:true,Float64Array:true,Int16Array:true,Int32Array:true,Int8Array:true,Uint16Array:true,Uint32Array:true,Uint8ClampedArray:true,CanvasPixelArray:true,Uint8Array:false})
A.dC.$nativeSuperclassTag="ArrayBufferView"
A.fw.$nativeSuperclassTag="ArrayBufferView"
A.fx.$nativeSuperclassTag="ArrayBufferView"
A.cj.$nativeSuperclassTag="ArrayBufferView"
A.fy.$nativeSuperclassTag="ArrayBufferView"
A.fz.$nativeSuperclassTag="ArrayBufferView"
A.bh.$nativeSuperclassTag="ArrayBufferView"})()
Function.prototype.$0=function(){return this()}
Function.prototype.$1=function(a){return this(a)}
Function.prototype.$2=function(a,b){return this(a,b)}
Function.prototype.$3$1=function(a){return this(a)}
Function.prototype.$2$1=function(a){return this(a)}
Function.prototype.$1$1=function(a){return this(a)}
Function.prototype.$3=function(a,b,c){return this(a,b,c)}
Function.prototype.$4=function(a,b,c,d){return this(a,b,c,d)}
Function.prototype.$3$3=function(a,b,c){return this(a,b,c)}
Function.prototype.$2$2=function(a,b){return this(a,b)}
Function.prototype.$6=function(a,b,c,d,e,f){return this(a,b,c,d,e,f)}
Function.prototype.$5=function(a,b,c,d,e){return this(a,b,c,d,e)}
convertAllToFastObject(w)
convertToFastObject($);(function(a){if(typeof document==="undefined"){a(null)
return}if(typeof document.currentScript!="undefined"){a(document.currentScript)
return}var s=document.scripts
function onLoad(b){for(var q=0;q<s.length;++q){s[q].removeEventListener("load",onLoad,false)}a(b.target)}for(var r=0;r<s.length;++r){s[r].addEventListener("load",onLoad,false)}})(function(a){v.currentScript=a
var s=A.on
if(typeof dartMainRunner==="function"){dartMainRunner(s,[])}else{s([])}})})()
//# sourceMappingURL=ultsql_engine.js.map
