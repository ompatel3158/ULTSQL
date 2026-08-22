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
if(a[b]!==s){A.wn(b)}a[b]=r}var q=a[b]
a[c]=function(){return q}
return q}}function makeConstList(a,b){if(b!=null)A.a(a,b)
a.$flags=7
return a}function convertToFastObject(a){function t(){}t.prototype=a
new t()
return a}function convertAllToFastObject(a){for(var s=0;s<a.length;++s){convertToFastObject(a[s])}}var y=0
function instanceTearOffGetter(a,b){var s=null
return a?function(c){if(s===null)s=A.pq(b)
return new s(c,this)}:function(){if(s===null)s=A.pq(b)
return new s(this,null)}}function staticTearOffGetter(a){var s=null
return function(){if(s===null)s=A.pq(a).prototype
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
pu(a,b,c,d){return{i:a,p:b,e:c,x:d}},
oh(a){var s,r,q,p,o,n=a[v.dispatchPropertyName]
if(n==null)if($.ps==null){A.w8()
n=a[v.dispatchPropertyName]}if(n!=null){s=n.p
if(!1===s)return n.i
if(!0===s)return a
r=Object.getPrototypeOf(a)
if(s===r)return n.i
if(n.e===r)throw A.c(A.qs("Return interceptor for "+A.D(s(a,n))))}q=a.constructor
if(q==null)p=null
else{o=$.nG
if(o==null)o=$.nG=v.getIsolateTag("_$dart_js")
p=q[o]}if(p!=null)return p
p=A.wc(a)
if(p!=null)return p
if(typeof a=="function")return B.cD
s=Object.getPrototypeOf(a)
if(s==null)return B.ba
if(s===Object.prototype)return B.ba
if(typeof q=="function"){o=$.nG
if(o==null)o=$.nG=v.getIsolateTag("_$dart_js")
Object.defineProperty(q,o,{value:B.b1,enumerable:false,writable:true,configurable:true})
return B.b1}return B.b1},
q0(a,b){if(a<0||a>4294967295)throw A.c(A.ax(a,0,4294967295,"length",null))
return J.tm(new Array(a),b)},
oP(a,b){if(a<0)throw A.c(A.bl("Length must be a non-negative integer: "+a,null))
return A.a(new Array(a),b.i("C<0>"))},
dz(a,b){if(a<0)throw A.c(A.bl("Length must be a non-negative integer: "+a,null))
return A.a(new Array(a),b.i("C<0>"))},
tm(a,b){var s=A.a(a,b.i("C<0>"))
s.$flags=1
return s},
tn(a,b){return J.pB(a,b)},
q1(a){if(a<256)switch(a){case 9:case 10:case 11:case 12:case 13:case 32:case 133:case 160:return!0
default:return!1}switch(a){case 5760:case 8192:case 8193:case 8194:case 8195:case 8196:case 8197:case 8198:case 8199:case 8200:case 8201:case 8202:case 8232:case 8233:case 8239:case 8287:case 12288:case 65279:return!0
default:return!1}},
to(a,b){var s,r
for(s=a.length;b<s;){r=a.charCodeAt(b)
if(r!==32&&r!==13&&!J.q1(r))break;++b}return b},
tp(a,b){var s,r
for(;b>0;b=s){s=b-1
r=a.charCodeAt(s)
if(r!==32&&r!==13&&!J.q1(r))break}return b},
d7(a){if(typeof a=="number"){if(Math.floor(a)==a)return J.eD.prototype
return J.hr.prototype}if(typeof a=="string")return J.ck.prototype
if(a==null)return J.eE.prototype
if(typeof a=="boolean")return J.eC.prototype
if(Array.isArray(a))return J.C.prototype
if(typeof a!="object"){if(typeof a=="function")return J.be.prototype
if(typeof a=="symbol")return J.dC.prototype
if(typeof a=="bigint")return J.dB.prototype
return a}if(a instanceof A.A)return a
return J.oh(a)},
X(a){if(typeof a=="string")return J.ck.prototype
if(a==null)return a
if(Array.isArray(a))return J.C.prototype
if(typeof a!="object"){if(typeof a=="function")return J.be.prototype
if(typeof a=="symbol")return J.dC.prototype
if(typeof a=="bigint")return J.dB.prototype
return a}if(a instanceof A.A)return a
return J.oh(a)},
bb(a){if(a==null)return a
if(Array.isArray(a))return J.C.prototype
if(typeof a!="object"){if(typeof a=="function")return J.be.prototype
if(typeof a=="symbol")return J.dC.prototype
if(typeof a=="bigint")return J.dB.prototype
return a}if(a instanceof A.A)return a
return J.oh(a)},
r5(a){if(typeof a=="number")return J.cM.prototype
if(a==null)return a
if(!(a instanceof A.A))return J.cu.prototype
return a},
pr(a){if(typeof a=="number")return J.cM.prototype
if(typeof a=="string")return J.ck.prototype
if(a==null)return a
if(!(a instanceof A.A))return J.cu.prototype
return a},
e3(a){if(typeof a=="string")return J.ck.prototype
if(a==null)return a
if(!(a instanceof A.A))return J.cu.prototype
return a},
e4(a){if(a==null)return a
if(typeof a!="object"){if(typeof a=="function")return J.be.prototype
if(typeof a=="symbol")return J.dC.prototype
if(typeof a=="bigint")return J.dB.prototype
return a}if(a instanceof A.A)return a
return J.oh(a)},
rF(a,b){if(typeof a=="number"&&typeof b=="number")return a+b
return J.pr(a).aq(a,b)},
rG(a,b){if(typeof a=="number"&&typeof b=="number")return a/b
return J.r5(a).aE(a,b)},
az(a,b){if(a==null)return b==null
if(typeof a!="object")return b!=null&&a===b
return J.d7(a).aw(a,b)},
rH(a,b){if(typeof a=="number"&&typeof b=="number")return a*b
return J.pr(a).P(a,b)},
rI(a,b){if(typeof a=="number"&&typeof b=="number")return a-b
return J.r5(a).aH(a,b)},
a_(a,b){if(typeof b==="number")if(Array.isArray(a)||typeof a=="string"||A.r8(a,a[v.dispatchPropertyName]))if(b>>>0===b&&b<a.length)return a[b]
return J.X(a).h(a,b)},
aX(a,b,c){if(typeof b==="number")if((Array.isArray(a)||A.r8(a,a[v.dispatchPropertyName]))&&!(a.$flags&2)&&b>>>0===b&&b<a.length)return a[b]=c
return J.bb(a).k(a,b,c)},
ix(a,b,c){return J.e4(a).hO(a,b,c)},
iy(a,b,c,d){return J.e4(a).io(a,b,c,d)},
ae(a,b){return J.bb(a).R(a,b)},
pA(a,b){return J.e3(a).f5(a,b)},
rJ(a,b){return J.bb(a).b1(a,b)},
rK(a,b,c){return J.e4(a).f6(a,b,c)},
rL(a,b,c){return J.e4(a).f7(a,b,c)},
rM(a,b,c){return J.e4(a).f8(a,b,c)},
ox(a){return J.e4(a).f9(a)},
bk(a,b,c){return J.e4(a).cj(a,b,c)},
pB(a,b){return J.pr(a).A(a,b)},
pC(a,b){return J.bb(a).an(a,b)},
rN(a,b){return J.e3(a).B(a,b)},
rO(a,b,c){return J.bb(a).fj(a,b,c)},
e6(a){return J.bb(a).gH(a)},
by(a){return J.d7(a).gY(a)},
pD(a){return J.X(a).ga9(a)},
pE(a){return J.X(a).gaa(a)},
au(a){return J.bb(a).gI(a)},
O(a){return J.X(a).gt(a)},
rP(a){return J.d7(a).gak(a)},
oy(a,b){return J.bb(a).S(a,b)},
bG(a,b,c){return J.bb(a).bd(a,b,c)},
rQ(a,b,c){return J.e3(a).dH(a,b,c)},
pF(a,b){return J.bb(a).aM(a,b)},
pG(a,b){return J.bb(a).ar(a,b)},
oz(a,b){return J.e3(a).cR(a,b)},
rR(a,b){return J.e3(a).U(a,b)},
rS(a,b,c){return J.e3(a).O(a,b,c)},
fX(a){return J.bb(a).aN(a)},
x(a){return J.d7(a).l(a)},
hm:function hm(){},
eC:function eC(){},
eE:function eE(){},
ar:function ar(){},
cl:function cl(){},
hI:function hI(){},
cu:function cu(){},
be:function be(){},
dB:function dB(){},
dC:function dC(){},
C:function C(a){this.$ti=a},
hq:function hq(){},
l2:function l2(a){this.$ti=a},
bd:function bd(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.d=null
_.$ti=c},
cM:function cM(){},
eD:function eD(){},
hr:function hr(){},
ck:function ck(){}},A={oR:function oR(){},
q4(a){return new A.cO("Field '"+a+"' has not been initialized.")},
tr(a){return new A.cO("Field '"+a+"' has already been initialized.")},
ct(a,b){a=a+b&536870911
a=a+((a&524287)<<10)&536870911
return a^a>>>6},
p5(a){a=a+((a&67108863)<<3)&536870911
a^=a>>>11
return a+((a&16383)<<15)&536870911},
cz(a,b,c){return a},
pt(a){var s,r
for(s=$.d5.length,r=0;r<s;++r)if(a===$.d5[r])return!0
return!1},
hQ(a,b,c,d){A.eX(b,"start")
if(c!=null){A.eX(c,"end")
if(b>c)A.ap(A.ax(b,0,c,"start",null))}return new A.fi(a,b,c,d.i("fi<0>"))},
oX(a,b,c,d){if(t.gw.b(a))return new A.en(a,b,c.i("@<0>").au(d).i("en<1,2>"))
return new A.cR(a,b,c.i("@<0>").au(d).i("cR<1,2>"))},
bZ(){return new A.cq("No element")},
pZ(){return new A.cq("Too few elements")},
hP(a,b,c,d){if(c-b<=32)A.tM(a,b,c,d)
else A.tL(a,b,c,d)},
tM(a,b,c,d){var s,r,q,p,o
for(s=b+1,r=J.X(a);s<=c;++s){q=r.h(a,s)
p=s
for(;;){if(!(p>b&&d.$2(r.h(a,p-1),q)>0))break
o=p-1
r.k(a,p,r.h(a,o))
p=o}r.k(a,p,q)}},
tL(a3,a4,a5,a6){var s,r,q,p,o,n,m,l,k,j,i=B.c.a3(a5-a4+1,6),h=a4+i,g=a5-i,f=B.c.a3(a4+a5,2),e=f-i,d=f+i,c=J.X(a3),b=c.h(a3,h),a=c.h(a3,e),a0=c.h(a3,f),a1=c.h(a3,d),a2=c.h(a3,g)
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
A.hP(a3,a4,r-2,a6)
A.hP(a3,q+2,a5,a6)
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
break}}A.hP(a3,r,q,a6)}else A.hP(a3,r,q,a6)},
nm:function nm(a){this.a=0
this.b=a},
cO:function cO(a){this.a=a},
de:function de(a){this.a=a},
mM:function mM(){},
H:function H(){},
u:function u(){},
fi:function fi(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.$ti=d},
cQ:function cQ(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.d=null
_.$ti=c},
cR:function cR(a,b,c){this.a=a
this.b=b
this.$ti=c},
en:function en(a,b,c){this.a=a
this.b=b
this.$ti=c},
eH:function eH(a,b,c){var _=this
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
fq:function fq(a,b,c){this.a=a
this.b=b
this.$ti=c},
bX:function bX(a,b,c){this.a=a
this.b=b
this.$ti=c},
er:function er(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=null
_.$ti=d},
ep:function ep(a){this.$ti=a},
ev:function ev(){},
hW:function hW(){},
dW:function dW(){},
f0:function f0(a,b){this.a=a
this.$ti=b},
hR:function hR(a){this.a=a},
oC(){throw A.c(A.Y("Cannot modify unmodifiable Map"))},
t_(){throw A.c(A.Y("Cannot modify constant Set"))},
rg(a){var s=v.mangledGlobalNames[a]
if(s!=null)return s
return"minified:"+a},
r8(a,b){var s
if(b!=null){s=b.x
if(s!=null)return s}return t.aU.b(a)},
D(a){var s
if(typeof a=="string")return a
if(typeof a=="number"){if(a!==0)return""+a}else if(!0===a)return"true"
else if(!1===a)return"false"
else if(a==null)return"null"
s=J.x(a)
return s},
hJ(a){var s,r=$.qc
if(r==null)r=$.qc=Symbol("identityHashCode")
s=a[r]
if(s==null){s=Math.random()*0x3fffffff|0
a[r]=s}return s},
a3(a,b){var s,r=/^\s*[+-]?((0x[a-f0-9]+)|(\d+)|([a-z0-9]+))\s*$/i.exec(a)
if(r==null)return null
s=r[3]
if(s!=null)return parseInt(a,10)
if(r[2]!=null)return parseInt(a,16)
return null},
aH(a){var s,r
if(!/^\s*[+-]?(?:Infinity|NaN|(?:\.\d+|\d+(?:\.\d*)?)(?:[eE][+-]?\d+)?)\s*$/.test(a))return null
s=parseFloat(a)
if(isNaN(s)){r=B.a.W(a)
if(r==="NaN"||r==="+NaN"||r==="-NaN")return s
return null}return s},
eV(a){var s,r,q,p
if(a instanceof A.A)return A.bj(A.bQ(a),null)
s=J.d7(a)
if(s===B.cB||s===B.cE||t.ak.b(a)){r=B.b6(a)
if(r!=="Object"&&r!=="")return r
q=a.constructor
if(typeof q=="function"){p=q.name
if(typeof p=="string"&&p!=="Object"&&p!=="")return p}}return A.bj(A.bQ(a),null)},
qe(a){var s,r,q
if(a==null||typeof a=="number"||A.fP(a))return J.x(a)
if(typeof a=="string")return JSON.stringify(a)
if(a instanceof A.cE)return a.l(0)
if(a instanceof A.fG)return a.f1(!0)
s=$.rD()
for(r=0;r<1;++r){q=s[r].jg(a)
if(q!=null)return q}return"Instance of '"+A.eV(a)+"'"},
tz(){return Date.now()},
tB(){var s,r
if($.ml!==0)return
$.ml=1000
if(typeof window=="undefined")return
s=window
if(s==null)return
if(!!s.dartUseDateNowForTicks)return
r=s.performance
if(r==null)return
if(typeof r.now!="function")return
$.ml=1e6
$.bs=new A.mk(r)},
tC(a,b,c){var s,r,q,p
if(c<=500&&b===0&&c===a.length)return String.fromCharCode.apply(null,a)
for(s=b,r="";s<c;s=q){q=s+500
p=q<c?q:c
r+=String.fromCharCode.apply(null,a.subarray(s,p))}return r},
at(a){var s
if(a<=65535)return String.fromCharCode(a)
if(a<=1114111){s=a-65536
return String.fromCharCode((B.c.bW(s,10)|55296)>>>0,s&1023|56320)}throw A.c(A.ax(a,0,1114111,null,null))},
tD(a,b,c,d,e,f,g,h,i){var s,r,q,p=b-1
if(0<=a&&a<100){a+=400
p-=4800}s=B.c.a7(h,1000)
g+=B.c.a3(h-s,1000)
r=i?Date.UTC(a,p,c,d,e,f,g):new Date(a,p,c,d,e,f,g).valueOf()
q=!0
if(!isNaN(r))if(!(r<-864e13))if(!(r>864e13))q=r===864e13&&s!==0
if(q)return null
return r},
bh(a){if(a.date===void 0)a.date=new Date(a.a)
return a.date},
b1(a){return a.c?A.bh(a).getUTCFullYear()+0:A.bh(a).getFullYear()+0},
bB(a){return a.c?A.bh(a).getUTCMonth()+1:A.bh(a).getMonth()+1},
bI(a){return a.c?A.bh(a).getUTCDate()+0:A.bh(a).getDate()+0},
dN(a){return a.c?A.bh(a).getUTCHours()+0:A.bh(a).getHours()+0},
eT(a){return a.c?A.bh(a).getUTCMinutes()+0:A.bh(a).getMinutes()+0},
eU(a){return a.c?A.bh(a).getUTCSeconds()+0:A.bh(a).getSeconds()+0},
qd(a){return a.c?A.bh(a).getUTCMilliseconds()+0:A.bh(a).getMilliseconds()+0},
tA(a){var s=a.$thrownJsError
if(s==null)return null
return A.bP(s)},
p_(a,b){var s
if(a.$thrownJsError==null){s=new Error()
A.aC(a,s)
a.$thrownJsError=s
s.stack=b.l(0)}},
oc(a,b){var s,r="index"
if(!A.fQ(b))return new A.bz(!0,b,r,null)
s=J.O(a)
if(b<0||b>=s)return A.oN(b,s,a,r)
return A.mG(b,r)},
w0(a,b,c){if(a>c)return A.ax(a,0,c,"start",null)
if(b!=null)if(b<a||b>c)return A.ax(b,a,c,"end",null)
return new A.bz(!0,b,"end",null)},
vF(a){return new A.bz(!0,a,null,null)},
c(a){return A.aC(a,new Error())},
aC(a,b){var s
if(a==null)a=new A.c7()
b.dartException=a
s=A.wo
if("defineProperty" in Object){Object.defineProperty(b,"message",{get:s})
b.name=""}else b.toString=s
return b},
wo(){return J.x(this.dartException)},
ap(a,b){throw A.aC(a,b==null?new Error():b)},
i(a,b,c){var s
if(b==null)b=0
if(c==null)c=0
s=Error()
A.ap(A.uV(a,b,c),s)},
uV(a,b,c){var s,r,q,p,o,n,m,l,k
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
return new A.fn("'"+s+"': Cannot "+o+" "+l+k+n)},
n(a){throw A.c(A.aA(a))},
c8(a){var s,r,q,p,o,n
a=A.iv(a.replace(String({}),"$receiver$"))
s=a.match(/\\\$[a-zA-Z]+\\\$/g)
if(s==null)s=A.a([],t.s)
r=s.indexOf("\\$arguments\\$")
q=s.indexOf("\\$argumentsExpr\\$")
p=s.indexOf("\\$expr\\$")
o=s.indexOf("\\$method\\$")
n=s.indexOf("\\$receiver\\$")
return new A.n6(a.replace(new RegExp("\\\\\\$arguments\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$argumentsExpr\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$expr\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$method\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$receiver\\\\\\$","g"),"((?:x|[^x])*)"),r,q,p,o,n)},
n7(a){return function($expr$){var $argumentsExpr$="$arguments$"
try{$expr$.$method$($argumentsExpr$)}catch(s){return s.message}}(a)},
qr(a){return function($expr$){try{$expr$.$method$}catch(s){return s.message}}(a)},
oT(a,b){var s=b==null,r=s?null:b.method
return new A.hs(a,r,s?null:b.receiver)},
aU(a){if(a==null)return new A.lY(a)
if(a instanceof A.eq)return A.cB(a,a.a)
if(typeof a!=="object")return a
if("dartException" in a)return A.cB(a,a.dartException)
return A.vE(a)},
cB(a,b){if(t.Q.b(b))if(b.$thrownJsError==null)b.$thrownJsError=a
return b},
vE(a){var s,r,q,p,o,n,m,l,k,j,i,h,g
if(!("message" in a))return a
s=a.message
if("number" in a&&typeof a.number=="number"){r=a.number
q=r&65535
if((B.c.bW(r,16)&8191)===10)switch(q){case 438:return A.cB(a,A.oT(A.D(s)+" (Error "+q+")",null))
case 445:case 5007:A.D(s)
return A.cB(a,new A.eP())}}if(a instanceof TypeError){p=$.rn()
o=$.ro()
n=$.rp()
m=$.rq()
l=$.rt()
k=$.ru()
j=$.rs()
$.rr()
i=$.rw()
h=$.rv()
g=p.aW(s)
if(g!=null)return A.cB(a,A.oT(s,g))
else{g=o.aW(s)
if(g!=null){g.method="call"
return A.cB(a,A.oT(s,g))}else if(n.aW(s)!=null||m.aW(s)!=null||l.aW(s)!=null||k.aW(s)!=null||j.aW(s)!=null||m.aW(s)!=null||i.aW(s)!=null||h.aW(s)!=null)return A.cB(a,new A.eP())}return A.cB(a,new A.hV(typeof s=="string"?s:""))}if(a instanceof RangeError){if(typeof s=="string"&&s.indexOf("call stack")!==-1)return new A.ff()
s=function(b){try{return String(b)}catch(f){}return null}(a)
return A.cB(a,new A.bz(!1,null,null,typeof s=="string"?s.replace(/^RangeError:\s*/,""):s))}if(typeof InternalError=="function"&&a instanceof InternalError)if(typeof s=="string"&&s==="too much recursion")return new A.ff()
return a},
bP(a){var s
if(a instanceof A.eq)return a.b
if(a==null)return new A.fI(a)
s=a.$cachedTrace
if(s!=null)return s
s=new A.fI(a)
if(typeof a==="object")a.$cachedTrace=s
return s},
rb(a){if(a==null)return J.by(a)
if(typeof a=="object")return A.hJ(a)
return J.by(a)},
w5(a,b){var s,r,q,p=a.length
for(s=0;s<p;s=q){r=s+1
q=r+1
b.k(0,a[s],a[r])}return b},
v6(a,b,c,d,e,f){switch(b){case 0:return a.$0()
case 1:return a.$1(c)
case 2:return a.$2(c,d)
case 3:return a.$3(c,d,e)
case 4:return a.$4(c,d,e,f)}throw A.c(A.q("Unsupported number of arguments for wrapped closure"))},
fU(a,b){var s=a.$identity
if(!!s)return s
s=A.vY(a,b)
a.$identity=s
return s},
vY(a,b){var s
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
return function(c,d,e){return function(f,g,h,i){return e(c,d,f,g,h,i)}}(a,b,A.v6)},
rZ(a2){var s,r,q,p,o,n,m,l,k,j,i=a2.co,h=a2.iS,g=a2.iI,f=a2.nDA,e=a2.aI,d=a2.fs,c=a2.cs,b=d[0],a=c[0],a0=i[b],a1=a2.fT
a1.toString
s=h?Object.create(new A.mO().constructor.prototype):Object.create(new A.eb(null,null).constructor.prototype)
s.$initialize=s.constructor
r=h?function static_tear_off(){this.$initialize()}:function tear_off(a3,a4){this.$initialize(a3,a4)}
s.constructor=r
r.prototype=s
s.$_name=b
s.$_target=a0
q=!h
if(q)p=A.pM(b,a0,g,f)
else{s.$static_name=b
p=a0}s.$S=A.rV(a1,h,g)
s[a]=p
for(o=p,n=1;n<d.length;++n){m=d[n]
if(typeof m=="string"){l=i[m]
k=m
m=l}else k=""
j=c[n]
if(j!=null){if(q)m=A.pM(k,m,g,f)
s[j]=m}if(n===e)o=m}s.$C=o
s.$R=a2.rC
s.$D=a2.dV
return r},
rV(a,b,c){if(typeof a=="number")return a
if(typeof a=="string"){if(b)throw A.c("Cannot compute signature for static tearoff.")
return function(d,e){return function(){return e(this,d)}}(a,A.rT)}throw A.c("Error in functionType of tearoff")},
rW(a,b,c,d){var s=A.pL
switch(b?-1:a){case 0:return function(e,f){return function(){return f(this)[e]()}}(c,s)
case 1:return function(e,f){return function(g){return f(this)[e](g)}}(c,s)
case 2:return function(e,f){return function(g,h){return f(this)[e](g,h)}}(c,s)
case 3:return function(e,f){return function(g,h,i){return f(this)[e](g,h,i)}}(c,s)
case 4:return function(e,f){return function(g,h,i,j){return f(this)[e](g,h,i,j)}}(c,s)
case 5:return function(e,f){return function(g,h,i,j,k){return f(this)[e](g,h,i,j,k)}}(c,s)
default:return function(e,f){return function(){return e.apply(f(this),arguments)}}(d,s)}},
pM(a,b,c,d){if(c)return A.rY(a,b,d)
return A.rW(b.length,d,a,b)},
rX(a,b,c,d){var s=A.pL,r=A.rU
switch(b?-1:a){case 0:throw A.c(new A.hN("Intercepted function with no arguments."))
case 1:return function(e,f,g){return function(){return f(this)[e](g(this))}}(c,r,s)
case 2:return function(e,f,g){return function(h){return f(this)[e](g(this),h)}}(c,r,s)
case 3:return function(e,f,g){return function(h,i){return f(this)[e](g(this),h,i)}}(c,r,s)
case 4:return function(e,f,g){return function(h,i,j){return f(this)[e](g(this),h,i,j)}}(c,r,s)
case 5:return function(e,f,g){return function(h,i,j,k){return f(this)[e](g(this),h,i,j,k)}}(c,r,s)
case 6:return function(e,f,g){return function(h,i,j,k,l){return f(this)[e](g(this),h,i,j,k,l)}}(c,r,s)
default:return function(e,f,g){return function(){var q=[g(this)]
Array.prototype.push.apply(q,arguments)
return e.apply(f(this),q)}}(d,r,s)}},
rY(a,b,c){var s,r
if($.pJ==null)$.pJ=A.pI("interceptor")
if($.pK==null)$.pK=A.pI("receiver")
s=b.length
r=A.rX(s,c,a,b)
return r},
pq(a){return A.rZ(a)},
rT(a,b){return A.fN(v.typeUniverse,A.bQ(a.a),b)},
pL(a){return a.a},
rU(a){return a.b},
pI(a){var s,r,q,p=new A.eb("receiver","interceptor"),o=Object.getOwnPropertyNames(p)
o.$flags=1
s=o
for(o=s.length,r=0;r<o;++r){q=s[r]
if(p[q]===a)return q}throw A.c(A.bl("Field name "+a+" not found.",null))},
r6(a){return v.getIsolateTag(a)},
wc(a){var s,r,q,p,o,n=$.r7.$1(a),m=$.od[n]
if(m!=null){Object.defineProperty(a,v.dispatchPropertyName,{value:m,enumerable:false,writable:true,configurable:true})
return m.i}s=$.ol[n]
if(s!=null)return s
r=v.interceptorsByTag[n]
if(r==null){q=$.qZ.$2(a,n)
if(q!=null){m=$.od[q]
if(m!=null){Object.defineProperty(a,v.dispatchPropertyName,{value:m,enumerable:false,writable:true,configurable:true})
return m.i}s=$.ol[q]
if(s!=null)return s
r=v.interceptorsByTag[q]
n=q}}if(r==null)return null
s=r.prototype
p=n[0]
if(p==="!"){m=A.oo(s)
$.od[n]=m
Object.defineProperty(a,v.dispatchPropertyName,{value:m,enumerable:false,writable:true,configurable:true})
return m.i}if(p==="~"){$.ol[n]=s
return s}if(p==="-"){o=A.oo(s)
Object.defineProperty(Object.getPrototypeOf(a),v.dispatchPropertyName,{value:o,enumerable:false,writable:true,configurable:true})
return o.i}if(p==="+")return A.rd(a,s)
if(p==="*")throw A.c(A.qs(n))
if(v.leafTags[n]===true){o=A.oo(s)
Object.defineProperty(Object.getPrototypeOf(a),v.dispatchPropertyName,{value:o,enumerable:false,writable:true,configurable:true})
return o.i}else return A.rd(a,s)},
rd(a,b){var s=Object.getPrototypeOf(a)
Object.defineProperty(s,v.dispatchPropertyName,{value:J.pu(b,s,null,null),enumerable:false,writable:true,configurable:true})
return b},
oo(a){return J.pu(a,!1,null,!!a.$ibf)},
wd(a,b,c){var s=b.prototype
if(v.leafTags[a]===true)return A.oo(s)
else return J.pu(s,c,null,null)},
w8(){if(!0===$.ps)return
$.ps=!0
A.w9()},
w9(){var s,r,q,p,o,n,m,l
$.od=Object.create(null)
$.ol=Object.create(null)
A.w7()
s=v.interceptorsByTag
r=Object.getOwnPropertyNames(s)
if(typeof window!="undefined"){window
q=function(){}
for(p=0;p<r.length;++p){o=r[p]
n=$.re.$1(o)
if(n!=null){m=A.wd(o,s[o],n)
if(m!=null){Object.defineProperty(n,v.dispatchPropertyName,{value:m,enumerable:false,writable:true,configurable:true})
q.prototype=n}}}}for(p=0;p<r.length;++p){o=r[p]
if(/^[A-Za-z_]/.test(o)){l=s[o]
s["!"+o]=l
s["~"+o]=l
s["-"+o]=l
s["+"+o]=l
s["*"+o]=l}}},
w7(){var s,r,q,p,o,n,m=B.cp()
m=A.e2(B.cq,A.e2(B.cr,A.e2(B.b7,A.e2(B.b7,A.e2(B.cs,A.e2(B.ct,A.e2(B.cu(B.b6),m)))))))
if(typeof dartNativeDispatchHooksTransformer!="undefined"){s=dartNativeDispatchHooksTransformer
if(typeof s=="function")s=[s]
if(Array.isArray(s))for(r=0;r<s.length;++r){q=s[r]
if(typeof q=="function")m=q(m)||m}}p=m.getTag
o=m.getUnknownTag
n=m.prototypeForTag
$.r7=new A.oi(p)
$.qZ=new A.oj(o)
$.re=new A.ok(n)},
e2(a,b){return a(b)||b},
w_(a,b){var s=b.length,r=v.rttc[""+s+";"+a]
if(r==null)return null
if(s===0)return r
if(s===r.length)return r.apply(null,b)
return r(b)},
oQ(a,b,c,d,e,f){var s=b?"m":"",r=c?"":"i",q=d?"u":"",p=e?"s":"",o=function(g,h){try{return new RegExp(g,h)}catch(n){return n}}(a,s+r+q+p+f)
if(o instanceof RegExp)return o
throw A.c(A.cj("Illegal RegExp pattern ("+String(o)+")",a,null))},
wk(a,b,c){var s=a.indexOf(b,c)
return s>=0},
r2(a){if(a.indexOf("$",0)>=0)return a.replace(/\$/g,"$$$$")
return a},
iv(a){if(/[[\]{}()*+?.\\^$|]/.test(a))return a.replace(/[[\]{}()*+?.\\^$|]/g,"\\$&")
return a},
S(a,b,c){var s
if(typeof b=="string")return A.wm(a,b,c)
if(b instanceof A.dA){s=b.gez()
s.lastIndex=0
return a.replace(s,A.r2(c))}return A.wl(a,b,c)},
wl(a,b,c){var s,r,q,p
for(s=J.pA(b,a),s=s.gI(s),r=0,q="";s.p();){p=s.gF()
q=q+a.substring(r,p.gcS())+c
r=p.gcp()}s=q+a.substring(r)
return s.charCodeAt(0)==0?s:s},
wm(a,b,c){var s,r,q
if(b===""){if(a==="")return c
s=a.length
for(r=c,q=0;q<s;++q)r=r+a[q]+c
return r.charCodeAt(0)==0?r:r}if(a.indexOf(b,0)<0)return a
if(a.length<500||c.indexOf("$",0)>=0)return a.split(b).join(c)
return a.replace(new RegExp(A.iv(b),"g"),A.r2(c))},
ig:function ig(a,b){this.a=a
this.b=b},
ef:function ef(){},
eh:function eh(a,b,c){this.a=a
this.b=b
this.$ti=c},
cZ:function cZ(a,b){this.a=a
this.$ti=b},
d_:function d_(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.d=null
_.$ti=c},
eg:function eg(){},
bT:function bT(a,b,c){this.a=a
this.b=b
this.$ti=c},
mk:function mk(a){this.a=a},
f5:function f5(){},
n6:function n6(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f},
eP:function eP(){},
hs:function hs(a,b,c){this.a=a
this.b=b
this.c=c},
hV:function hV(a){this.a=a},
lY:function lY(a){this.a=a},
eq:function eq(a,b){this.a=a
this.b=b},
fI:function fI(a){this.a=a
this.b=null},
cE:function cE(){},
iQ:function iQ(){},
iR:function iR(){},
n4:function n4(){},
mO:function mO(){},
eb:function eb(a,b){this.a=a
this.b=b},
hN:function hN(a){this.a=a},
c0:function c0(a){var _=this
_.a=0
_.f=_.e=_.d=_.c=_.b=null
_.r=0
_.$ti=a},
lM:function lM(a){this.a=a},
lQ:function lQ(a,b){var _=this
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
b0:function b0(a,b){this.a=a
this.$ti=b},
an:function an(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=null
_.$ti=d},
am:function am(a,b){this.a=a
this.$ti=b},
eG:function eG(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=null
_.$ti=d},
oi:function oi(a){this.a=a},
oj:function oj(a){this.a=a},
ok:function ok(a){this.a=a},
fG:function fG(){},
ie:function ie(){},
dA:function dA(a,b){var _=this
_.a=a
_.b=b
_.e=_.d=_.c=null},
dZ:function dZ(a){this.b=a},
i0:function i0(a,b,c){this.a=a
this.b=b
this.c=c},
i1:function i1(a,b,c){var _=this
_.a=a
_.b=b
_.c=c
_.d=null},
dT:function dT(a,b){this.a=a
this.c=b},
ij:function ij(a,b,c){this.a=a
this.b=b
this.c=c},
ik:function ik(a,b,c){var _=this
_.a=a
_.b=b
_.c=c
_.d=null},
wn(a){throw A.aC(new A.cO("Field '"+a+"' has been assigned during initialization."),new Error())},
b(){throw A.aC(A.q4(""),new Error())},
bc(){throw A.aC(A.tr(""),new Error())},
qu(){var s=new A.nl()
return s.b=s},
nl:function nl(){this.b=null},
d3(a,b,c){},
bx(a){var s,r,q
if(t.aP.b(a))return a
s=J.X(a)
r=A.a9(s.gt(a),null,!1,t.z)
for(q=0;q<s.gt(a);++q)r[q]=s.h(a,q)
return r},
tt(a,b,c){var s
A.d3(a,b,c)
s=new DataView(a,b,c)
return s},
tu(a,b,c){A.d3(a,b,c)
return new Float64Array(a,b,c)},
tv(a,b,c){A.d3(a,b,c)
return new Int32Array(a,b,c)},
lW(a){return new Uint8Array(a)},
tw(a,b,c){A.d3(a,b,c)
return c==null?new Uint8Array(a,b):new Uint8Array(a,b,c)},
cb(a,b,c){if(a>>>0!==a||a>=c)throw A.c(A.oc(b,a))},
pe(a,b,c){var s
if(!(a>>>0!==a))s=b>>>0!==b||a>b||b>c
else s=!0
if(s)throw A.c(A.w0(a,b,c))
return b},
dF:function dF(){},
eM:function eM(){},
nV:function nV(a){this.a=a},
eJ:function eJ(){},
dG:function dG(){},
cn:function cn(){},
bg:function bg(){},
hu:function hu(){},
eK:function eK(){},
hv:function hv(){},
eL:function eL(){},
hw:function hw(){},
hx:function hx(){},
hy:function hy(){},
eN:function eN(){},
eO:function eO(){},
fC:function fC(){},
fD:function fD(){},
fE:function fE(){},
fF:function fF(){},
p1(a,b){var s=b.c
return s==null?b.c=A.fL(a,"b7",[b.x]):s},
qj(a){var s=a.w
if(s===6||s===7)return A.qj(a.x)
return s===11||s===12},
tK(a){return a.as},
cc(a){return A.nU(v.typeUniverse,a,!1)},
d4(a1,a2,a3,a4){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0=a2.w
switch(a0){case 5:case 1:case 2:case 3:case 4:return a2
case 6:s=a2.x
r=A.d4(a1,s,a3,a4)
if(r===s)return a2
return A.qE(a1,r,!0)
case 7:s=a2.x
r=A.d4(a1,s,a3,a4)
if(r===s)return a2
return A.qD(a1,r,!0)
case 8:q=a2.y
p=A.e1(a1,q,a3,a4)
if(p===q)return a2
return A.fL(a1,a2.x,p)
case 9:o=a2.x
n=A.d4(a1,o,a3,a4)
m=a2.y
l=A.e1(a1,m,a3,a4)
if(n===o&&l===m)return a2
return A.pb(a1,n,l)
case 10:k=a2.x
j=a2.y
i=A.e1(a1,j,a3,a4)
if(i===j)return a2
return A.qF(a1,k,i)
case 11:h=a2.x
g=A.d4(a1,h,a3,a4)
f=a2.y
e=A.vB(a1,f,a3,a4)
if(g===h&&e===f)return a2
return A.qC(a1,g,e)
case 12:d=a2.y
a4+=d.length
c=A.e1(a1,d,a3,a4)
o=a2.x
n=A.d4(a1,o,a3,a4)
if(c===d&&n===o)return a2
return A.pc(a1,n,c,!0)
case 13:b=a2.x
if(b<a4)return a2
a=a3[b-a4]
if(a==null)return a2
return a
default:throw A.c(A.e8("Attempted to substitute unexpected RTI kind "+a0))}},
e1(a,b,c,d){var s,r,q,p,o=b.length,n=A.nZ(o)
for(s=!1,r=0;r<o;++r){q=b[r]
p=A.d4(a,q,c,d)
if(p!==q)s=!0
n[r]=p}return s?n:b},
vC(a,b,c,d){var s,r,q,p,o,n,m=b.length,l=A.nZ(m)
for(s=!1,r=0;r<m;r+=3){q=b[r]
p=b[r+1]
o=b[r+2]
n=A.d4(a,o,c,d)
if(n!==o)s=!0
l.splice(r,3,q,p,n)}return s?l:b},
vB(a,b,c,d){var s,r=b.a,q=A.e1(a,r,c,d),p=b.b,o=A.e1(a,p,c,d),n=b.c,m=A.vC(a,n,c,d)
if(q===r&&o===p&&m===n)return b
s=new A.ia()
s.a=q
s.b=o
s.c=m
return s},
a(a,b){a[v.arrayRti]=b
return a},
r0(a){var s=a.$S
if(s!=null){if(typeof s=="number")return A.w6(s)
return a.$S()}return null},
wa(a,b){var s
if(A.qj(b))if(a instanceof A.cE){s=A.r0(a)
if(s!=null)return s}return A.bQ(a)},
bQ(a){if(a instanceof A.A)return A.E(a)
if(Array.isArray(a))return A.z(a)
return A.ph(J.d7(a))},
z(a){var s=a[v.arrayRti],r=t.gn
if(s==null)return r
if(s.constructor!==r.constructor)return r
return s},
E(a){var s=a.$ti
return s!=null?s:A.ph(a)},
ph(a){var s=a.constructor,r=s.$ccache
if(r!=null)return r
return A.v3(a,s)},
v3(a,b){var s=a instanceof A.cE?Object.getPrototypeOf(Object.getPrototypeOf(a)).constructor:b,r=A.uz(v.typeUniverse,s.name)
b.$ccache=r
return r},
w6(a){var s,r=v.types,q=r[a]
if(typeof q=="string"){s=A.nU(v.typeUniverse,q,!1)
r[a]=s
return s}return q},
fV(a){return A.d6(A.E(a))},
pp(a){var s
if(a instanceof A.fG)return A.w3(a.$r,a.en())
s=a instanceof A.cE?A.r0(a):null
if(s!=null)return s
if(t.dm.b(a))return J.rP(a).a
if(Array.isArray(a))return A.z(a)
return A.bQ(a)},
d6(a){var s=a.r
return s==null?a.r=new A.nT(a):s},
w3(a,b){var s,r,q=b,p=q.length
if(p===0)return t.bQ
s=A.fN(v.typeUniverse,A.pp(q[0]),"@<0>")
for(r=1;r<p;++r)s=A.qG(v.typeUniverse,s,A.pp(q[r]))
return A.fN(v.typeUniverse,s,a)},
bF(a){return A.d6(A.nU(v.typeUniverse,a,!1))},
v2(a){var s=this
s.b=A.vz(s)
return s.b(a)},
vz(a){var s,r,q,p
if(a===t.C)return A.vc
if(A.d9(a))return A.vg
s=a.w
if(s===6)return A.uZ
if(s===1)return A.qQ
if(s===7)return A.v7
r=A.vy(a)
if(r!=null)return r
if(s===8){q=a.x
if(a.y.every(A.d9)){a.f="$i"+q
if(q==="t")return A.va
if(a===t.eH)return A.v9
return A.vf}}else if(s===10){p=A.w_(a.x,a.y)
return p==null?A.qQ:p}return A.uX},
vy(a){if(a.w===8){if(a===t.S)return A.fQ
if(a===t.i||a===t.di)return A.vb
if(a===t.N)return A.ve
if(a===t.y)return A.fP}return null},
v1(a){var s=this,r=A.uW
if(A.d9(s))r=A.uP
else if(s===t.C)r=A.uN
else if(A.e5(s)){r=A.uY
if(s===t.h6)r=A.uJ
else if(s===t.T)r=A.uO
else if(s===t.fQ)r=A.uG
else if(s===t.e6)r=A.uM
else if(s===t.cD)r=A.uI
else if(s===t.an)r=A.uL}else if(s===t.S)r=A.qK
else if(s===t.N)r=A.is
else if(s===t.y)r=A.uF
else if(s===t.di)r=A.ir
else if(s===t.i)r=A.uH
else if(s===t.eH)r=A.uK
s.a=r
return s.a(a)},
uX(a){var s=this
if(a==null)return A.e5(s)
return A.wb(v.typeUniverse,A.wa(a,s),s)},
uZ(a){if(a==null)return!0
return this.x.b(a)},
vf(a){var s,r=this
if(a==null)return A.e5(r)
s=r.f
if(a instanceof A.A)return!!a[s]
return!!J.d7(a)[s]},
va(a){var s,r=this
if(a==null)return A.e5(r)
if(typeof a!="object")return!1
if(Array.isArray(a))return!0
s=r.f
if(a instanceof A.A)return!!a[s]
return!!J.d7(a)[s]},
v9(a){var s=this
if(a==null)return!1
if(typeof a=="object"){if(a instanceof A.A)return!!a[s.f]
return!0}if(typeof a=="function")return!0
return!1},
qP(a){if(typeof a=="object"){if(a instanceof A.A)return t.eH.b(a)
return!0}if(typeof a=="function")return!0
return!1},
uW(a){var s=this
if(a==null){if(A.e5(s))return a}else if(s.b(a))return a
throw A.aC(A.qL(a,s),new Error())},
uY(a){var s=this
if(a==null||s.b(a))return a
throw A.aC(A.qL(a,s),new Error())},
qL(a,b){return new A.fJ("TypeError: "+A.qv(a,A.bj(b,null)))},
qv(a,b){return A.hc(a)+": type '"+A.bj(A.pp(a),null)+"' is not a subtype of type '"+b+"'"},
bw(a,b){return new A.fJ("TypeError: "+A.qv(a,b))},
v7(a){var s=this
return s.x.b(a)||A.p1(v.typeUniverse,s).b(a)},
vc(a){return a!=null},
uN(a){if(a!=null)return a
throw A.aC(A.bw(a,"Object"),new Error())},
vg(a){return!0},
uP(a){return a},
qQ(a){return!1},
fP(a){return!0===a||!1===a},
uF(a){if(!0===a)return!0
if(!1===a)return!1
throw A.aC(A.bw(a,"bool"),new Error())},
uG(a){if(!0===a)return!0
if(!1===a)return!1
if(a==null)return a
throw A.aC(A.bw(a,"bool?"),new Error())},
uH(a){if(typeof a=="number")return a
throw A.aC(A.bw(a,"double"),new Error())},
uI(a){if(typeof a=="number")return a
if(a==null)return a
throw A.aC(A.bw(a,"double?"),new Error())},
fQ(a){return typeof a=="number"&&Math.floor(a)===a},
qK(a){if(typeof a=="number"&&Math.floor(a)===a)return a
throw A.aC(A.bw(a,"int"),new Error())},
uJ(a){if(typeof a=="number"&&Math.floor(a)===a)return a
if(a==null)return a
throw A.aC(A.bw(a,"int?"),new Error())},
vb(a){return typeof a=="number"},
ir(a){if(typeof a=="number")return a
throw A.aC(A.bw(a,"num"),new Error())},
uM(a){if(typeof a=="number")return a
if(a==null)return a
throw A.aC(A.bw(a,"num?"),new Error())},
ve(a){return typeof a=="string"},
is(a){if(typeof a=="string")return a
throw A.aC(A.bw(a,"String"),new Error())},
uO(a){if(typeof a=="string")return a
if(a==null)return a
throw A.aC(A.bw(a,"String?"),new Error())},
uK(a){if(A.qP(a))return a
throw A.aC(A.bw(a,"JSObject"),new Error())},
uL(a){if(a==null)return a
if(A.qP(a))return a
throw A.aC(A.bw(a,"JSObject?"),new Error())},
qW(a,b){var s,r,q
for(s="",r="",q=0;q<a.length;++q,r=", ")s+=r+A.bj(a[q],b)
return s},
vo(a,b){var s,r,q,p,o,n,m=a.x,l=a.y
if(""===m)return"("+A.qW(l,b)+")"
s=l.length
r=m.split(",")
q=r.length-s
for(p="(",o="",n=0;n<s;++n,o=", "){p+=o
if(q===0)p+="{"
p+=A.bj(l[n],b)
if(q>=0)p+=" "+r[q];++q}return p+"})"},
qM(a1,a2,a3){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a=", ",a0=null
if(a3!=null){s=a3.length
if(a2==null)a2=A.a([],t.s)
else a0=a2.length
r=a2.length
for(q=s;q>0;--q)a2.push("T"+(r+q))
for(p=t.X,o="<",n="",q=0;q<s;++q,n=a){o=o+n+a2[a2.length-1-q]
m=a3[q]
l=m.w
if(!(l===2||l===3||l===4||l===5||m===p))o+=" extends "+A.bj(m,a2)}o+=">"}else o=""
p=a1.x
k=a1.y
j=k.a
i=j.length
h=k.b
g=h.length
f=k.c
e=f.length
d=A.bj(p,a2)
for(c="",b="",q=0;q<i;++q,b=a)c+=b+A.bj(j[q],a2)
if(g>0){c+=b+"["
for(b="",q=0;q<g;++q,b=a)c+=b+A.bj(h[q],a2)
c+="]"}if(e>0){c+=b+"{"
for(b="",q=0;q<e;q+=3,b=a){c+=b
if(f[q+1])c+="required "
c+=A.bj(f[q+2],a2)+" "+f[q]}c+="}"}if(a0!=null){a2.toString
a2.length=a0}return o+"("+c+") => "+d},
bj(a,b){var s,r,q,p,o,n,m=a.w
if(m===5)return"erased"
if(m===2)return"dynamic"
if(m===3)return"void"
if(m===1)return"Never"
if(m===4)return"any"
if(m===6){s=a.x
r=A.bj(s,b)
q=s.w
return(q===11||q===12?"("+r+")":r)+"?"}if(m===7)return"FutureOr<"+A.bj(a.x,b)+">"
if(m===8){p=A.vD(a.x)
o=a.y
return o.length>0?p+("<"+A.qW(o,b)+">"):p}if(m===10)return A.vo(a,b)
if(m===11)return A.qM(a,b,null)
if(m===12)return A.qM(a.x,b,a.y)
if(m===13){n=a.x
return b[b.length-1-n]}return"?"},
vD(a){var s=v.mangledGlobalNames[a]
if(s!=null)return s
return"minified:"+a},
uA(a,b){var s=a.tR[b]
while(typeof s=="string")s=a.tR[s]
return s},
uz(a,b){var s,r,q,p,o,n=a.eT,m=n[b]
if(m==null)return A.nU(a,b,!1)
else if(typeof m=="number"){s=m
r=A.fM(a,5,"#")
q=A.nZ(s)
for(p=0;p<s;++p)q[p]=r
o=A.fL(a,b,q)
n[b]=o
return o}else return m},
uy(a,b){return A.qI(a.tR,b)},
ux(a,b){return A.qI(a.eT,b)},
nU(a,b,c){var s,r=a.eC,q=r.get(b)
if(q!=null)return q
s=A.qz(A.qx(a,null,b,!1))
r.set(b,s)
return s},
fN(a,b,c){var s,r,q=b.z
if(q==null)q=b.z=new Map()
s=q.get(c)
if(s!=null)return s
r=A.qz(A.qx(a,b,c,!0))
q.set(c,r)
return r},
qG(a,b,c){var s,r,q,p=b.Q
if(p==null)p=b.Q=new Map()
s=c.as
r=p.get(s)
if(r!=null)return r
q=A.pb(a,b,c.w===9?c.y:[c])
p.set(s,q)
return q},
cy(a,b){b.a=A.v1
b.b=A.v2
return b},
fM(a,b,c){var s,r,q=a.eC.get(c)
if(q!=null)return q
s=new A.bD(null,null)
s.w=b
s.as=c
r=A.cy(a,s)
a.eC.set(c,r)
return r},
qE(a,b,c){var s,r=b.as+"?",q=a.eC.get(r)
if(q!=null)return q
s=A.uv(a,b,r,c)
a.eC.set(r,s)
return s},
uv(a,b,c,d){var s,r,q
if(d){s=b.w
r=!0
if(!A.d9(b))if(!(b===t.P||b===t.v))if(s!==6)r=s===7&&A.e5(b.x)
if(r)return b
else if(s===1)return t.P}q=new A.bD(null,null)
q.w=6
q.x=b
q.as=c
return A.cy(a,q)},
qD(a,b,c){var s,r=b.as+"/",q=a.eC.get(r)
if(q!=null)return q
s=A.ut(a,b,r,c)
a.eC.set(r,s)
return s},
ut(a,b,c,d){var s,r
if(d){s=b.w
if(A.d9(b)||b===t.C)return b
else if(s===1)return A.fL(a,"b7",[b])
else if(b===t.P||b===t.v)return t.bG}r=new A.bD(null,null)
r.w=7
r.x=b
r.as=c
return A.cy(a,r)},
uw(a,b){var s,r,q=""+b+"^",p=a.eC.get(q)
if(p!=null)return p
s=new A.bD(null,null)
s.w=13
s.x=b
s.as=q
r=A.cy(a,s)
a.eC.set(q,r)
return r},
fK(a){var s,r,q,p=a.length
for(s="",r="",q=0;q<p;++q,r=",")s+=r+a[q].as
return s},
us(a){var s,r,q,p,o,n=a.length
for(s="",r="",q=0;q<n;q+=3,r=","){p=a[q]
o=a[q+1]?"!":":"
s+=r+p+o+a[q+2].as}return s},
fL(a,b,c){var s,r,q,p=b
if(c.length>0)p+="<"+A.fK(c)+">"
s=a.eC.get(p)
if(s!=null)return s
r=new A.bD(null,null)
r.w=8
r.x=b
r.y=c
if(c.length>0)r.c=c[0]
r.as=p
q=A.cy(a,r)
a.eC.set(p,q)
return q},
pb(a,b,c){var s,r,q,p,o,n
if(b.w===9){s=b.x
r=b.y.concat(c)}else{r=c
s=b}q=s.as+(";<"+A.fK(r)+">")
p=a.eC.get(q)
if(p!=null)return p
o=new A.bD(null,null)
o.w=9
o.x=s
o.y=r
o.as=q
n=A.cy(a,o)
a.eC.set(q,n)
return n},
qF(a,b,c){var s,r,q="+"+(b+"("+A.fK(c)+")"),p=a.eC.get(q)
if(p!=null)return p
s=new A.bD(null,null)
s.w=10
s.x=b
s.y=c
s.as=q
r=A.cy(a,s)
a.eC.set(q,r)
return r},
qC(a,b,c){var s,r,q,p,o,n=b.as,m=c.a,l=m.length,k=c.b,j=k.length,i=c.c,h=i.length,g="("+A.fK(m)
if(j>0){s=l>0?",":""
g+=s+"["+A.fK(k)+"]"}if(h>0){s=l>0?",":""
g+=s+"{"+A.us(i)+"}"}r=n+(g+")")
q=a.eC.get(r)
if(q!=null)return q
p=new A.bD(null,null)
p.w=11
p.x=b
p.y=c
p.as=r
o=A.cy(a,p)
a.eC.set(r,o)
return o},
pc(a,b,c,d){var s,r=b.as+("<"+A.fK(c)+">"),q=a.eC.get(r)
if(q!=null)return q
s=A.uu(a,b,c,r,d)
a.eC.set(r,s)
return s},
uu(a,b,c,d,e){var s,r,q,p,o,n,m,l
if(e){s=c.length
r=A.nZ(s)
for(q=0,p=0;p<s;++p){o=c[p]
if(o.w===1){r[p]=o;++q}}if(q>0){n=A.d4(a,b,r,0)
m=A.e1(a,c,r,0)
return A.pc(a,n,m,c!==m)}}l=new A.bD(null,null)
l.w=12
l.x=b
l.y=c
l.as=d
return A.cy(a,l)},
qx(a,b,c,d){return{u:a,e:b,r:c,s:[],p:0,n:d}},
qz(a){var s,r,q,p,o,n,m,l=a.r,k=a.s
for(s=l.length,r=0;r<s;){q=l.charCodeAt(r)
if(q>=48&&q<=57)r=A.uf(r+1,q,l,k)
else if((((q|32)>>>0)-97&65535)<26||q===95||q===36||q===124)r=A.qy(a,r,l,k,!1)
else if(q===46)r=A.qy(a,r,l,k,!0)
else{++r
switch(q){case 44:break
case 58:k.push(!1)
break
case 33:k.push(!0)
break
case 59:k.push(A.d1(a.u,a.e,k.pop()))
break
case 94:k.push(A.uw(a.u,k.pop()))
break
case 35:k.push(A.fM(a.u,5,"#"))
break
case 64:k.push(A.fM(a.u,2,"@"))
break
case 126:k.push(A.fM(a.u,3,"~"))
break
case 60:k.push(a.p)
a.p=k.length
break
case 62:A.uh(a,k)
break
case 38:A.ug(a,k)
break
case 63:p=a.u
k.push(A.qE(p,A.d1(p,a.e,k.pop()),a.n))
break
case 47:p=a.u
k.push(A.qD(p,A.d1(p,a.e,k.pop()),a.n))
break
case 40:k.push(-3)
k.push(a.p)
a.p=k.length
break
case 41:A.ue(a,k)
break
case 91:k.push(a.p)
a.p=k.length
break
case 93:o=k.splice(a.p)
A.qA(a.u,a.e,o)
a.p=k.pop()
k.push(o)
k.push(-1)
break
case 123:k.push(a.p)
a.p=k.length
break
case 125:o=k.splice(a.p)
A.uj(a.u,a.e,o)
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
return A.d1(a.u,a.e,m)},
uf(a,b,c,d){var s,r,q=b-48
for(s=c.length;a<s;++a){r=c.charCodeAt(a)
if(!(r>=48&&r<=57))break
q=q*10+(r-48)}d.push(q)
return a},
qy(a,b,c,d,e){var s,r,q,p,o,n,m=b+1
for(s=c.length;m<s;++m){r=c.charCodeAt(m)
if(r===46){if(e)break
e=!0}else{if(!((((r|32)>>>0)-97&65535)<26||r===95||r===36||r===124))q=r>=48&&r<=57
else q=!0
if(!q)break}}p=c.substring(b,m)
if(e){s=a.u
o=a.e
if(o.w===9)o=o.x
n=A.uA(s,o.x)[p]
if(n==null)A.ap('No "'+p+'" in "'+A.tK(o)+'"')
d.push(A.fN(s,o,n))}else d.push(p)
return m},
uh(a,b){var s,r=a.u,q=A.qw(a,b),p=b.pop()
if(typeof p=="string")b.push(A.fL(r,p,q))
else{s=A.d1(r,a.e,p)
switch(s.w){case 11:b.push(A.pc(r,s,q,a.n))
break
default:b.push(A.pb(r,s,q))
break}}},
ue(a,b){var s,r,q,p=a.u,o=b.pop(),n=null,m=null
if(typeof o=="number")switch(o){case-1:n=b.pop()
break
case-2:m=b.pop()
break
default:b.push(o)
break}else b.push(o)
s=A.qw(a,b)
o=b.pop()
switch(o){case-3:o=b.pop()
if(n==null)n=p.sEA
if(m==null)m=p.sEA
r=A.d1(p,a.e,o)
q=new A.ia()
q.a=s
q.b=n
q.c=m
b.push(A.qC(p,r,q))
return
case-4:b.push(A.qF(p,b.pop(),s))
return
default:throw A.c(A.e8("Unexpected state under `()`: "+A.D(o)))}},
ug(a,b){var s=b.pop()
if(0===s){b.push(A.fM(a.u,1,"0&"))
return}if(1===s){b.push(A.fM(a.u,4,"1&"))
return}throw A.c(A.e8("Unexpected extended operation "+A.D(s)))},
qw(a,b){var s=b.splice(a.p)
A.qA(a.u,a.e,s)
a.p=b.pop()
return s},
d1(a,b,c){if(typeof c=="string")return A.fL(a,c,a.sEA)
else if(typeof c=="number"){b.toString
return A.ui(a,b,c)}else return c},
qA(a,b,c){var s,r=c.length
for(s=0;s<r;++s)c[s]=A.d1(a,b,c[s])},
uj(a,b,c){var s,r=c.length
for(s=2;s<r;s+=3)c[s]=A.d1(a,b,c[s])},
ui(a,b,c){var s,r,q=b.w
if(q===9){if(c===0)return b.x
s=b.y
r=s.length
if(c<=r)return s[c-1]
c-=r
b=b.x
q=b.w}else if(c===0)return b
if(q!==8)throw A.c(A.e8("Indexed base must be an interface type"))
s=b.y
if(c<=s.length)return s[c-1]
throw A.c(A.e8("Bad index "+c+" for "+b.l(0)))},
wb(a,b,c){var s,r=b.d
if(r==null)r=b.d=new Map()
s=r.get(c)
if(s==null){s=A.aF(a,b,null,c,null)
r.set(c,s)}return s},
aF(a,b,c,d,e){var s,r,q,p,o,n,m,l,k,j,i
if(b===d)return!0
if(A.d9(d))return!0
s=b.w
if(s===4)return!0
if(A.d9(b))return!1
if(b.w===1)return!0
r=s===13
if(r)if(A.aF(a,c[b.x],c,d,e))return!0
q=d.w
p=t.P
if(b===p||b===t.v){if(q===7)return A.aF(a,b,c,d.x,e)
return d===p||d===t.v||q===6}if(d===t.C){if(s===7)return A.aF(a,b.x,c,d,e)
return s!==6}if(s===7){if(!A.aF(a,b.x,c,d,e))return!1
return A.aF(a,A.p1(a,b),c,d,e)}if(s===6)return A.aF(a,p,c,d,e)&&A.aF(a,b.x,c,d,e)
if(q===7){if(A.aF(a,b,c,d.x,e))return!0
return A.aF(a,b,c,A.p1(a,d),e)}if(q===6)return A.aF(a,b,c,p,e)||A.aF(a,b,c,d.x,e)
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
if(!A.aF(a,j,c,i,e)||!A.aF(a,i,e,j,c))return!1}return A.qO(a,b.x,c,d.x,e)}if(q===11){if(b===t.g)return!0
if(p)return!1
return A.qO(a,b,c,d,e)}if(s===8){if(q!==8)return!1
return A.v8(a,b,c,d,e)}if(o&&q===10)return A.vd(a,b,c,d,e)
return!1},
qO(a3,a4,a5,a6,a7){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2
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
v8(a,b,c,d,e){var s,r,q,p,o,n=b.x,m=d.x
while(n!==m){s=a.tR[n]
if(s==null)return!1
if(typeof s=="string"){n=s
continue}r=s[m]
if(r==null)return!1
q=r.length
p=q>0?new Array(q):v.typeUniverse.sEA
for(o=0;o<q;++o)p[o]=A.fN(a,b,r[o])
return A.qJ(a,p,null,c,d.y,e)}return A.qJ(a,b.y,null,c,d.y,e)},
qJ(a,b,c,d,e,f){var s,r=b.length
for(s=0;s<r;++s)if(!A.aF(a,b[s],d,e[s],f))return!1
return!0},
vd(a,b,c,d,e){var s,r=b.y,q=d.y,p=r.length
if(p!==q.length)return!1
if(b.x!==d.x)return!1
for(s=0;s<p;++s)if(!A.aF(a,r[s],c,q[s],e))return!1
return!0},
e5(a){var s=a.w,r=!0
if(!(a===t.P||a===t.v))if(!A.d9(a))if(s!==6)r=s===7&&A.e5(a.x)
return r},
d9(a){var s=a.w
return s===2||s===3||s===4||s===5||a===t.X},
qI(a,b){var s,r,q=Object.keys(b),p=q.length
for(s=0;s<p;++s){r=q[s]
a[r]=b[r]}},
nZ(a){return a>0?new Array(a):v.typeUniverse.sEA},
bD:function bD(a,b){var _=this
_.a=a
_.b=b
_.r=_.f=_.d=_.c=null
_.w=0
_.as=_.Q=_.z=_.y=_.x=null},
ia:function ia(){this.c=this.b=this.a=null},
nT:function nT(a){this.a=a},
i9:function i9(){},
fJ:function fJ(a){this.a=a},
tV(){var s,r,q
if(self.scheduleImmediate!=null)return A.vG()
if(self.MutationObserver!=null&&self.document!=null){s={}
r=self.document.createElement("div")
q=self.document.createElement("span")
s.a=null
new self.MutationObserver(A.fU(new A.ni(s),1)).observe(r,{childList:true})
return new A.nh(s,r,q)}else if(self.setImmediate!=null)return A.vH()
return A.vI()},
tW(a){self.scheduleImmediate(A.fU(new A.nj(a),0))},
tX(a){self.setImmediate(A.fU(new A.nk(a),0))},
tY(a){A.qp(B.f,a)},
qp(a,b){var s=B.c.a3(a.a,1000)
return A.uq(s<0?0:s,b)},
uq(a,b){var s=new A.im()
s.fX(a,b)
return s},
ur(a,b){var s=new A.im()
s.fY(a,b)
return s},
b5(a){return new A.i2(new A.ad($.V,a.i("ad<0>")),a.i("i2<0>"))},
b4(a,b){a.$2(0,null)
b.b=!0
return b.a},
as(a,b){A.uQ(a,b)},
b3(a,b){b.fb(a)},
b2(a,b){b.fc(A.aU(a),A.bP(a))},
uQ(a,b){var s,r,q=new A.o_(b),p=new A.o0(b)
if(a instanceof A.ad)a.f0(q,p,t.z)
else{s=t.z
if(a instanceof A.ad)a.cI(q,p,s)
else{r=new A.ad($.V,t.eI)
r.a=8
r.c=a
r.f0(q,p,s)}}},
b6(a){var s=function(b,c){return function(d,e){while(true){try{b(d,e)
break}catch(r){e=r
d=c}}}}(a,1)
return $.V.dJ(new A.ob(s),t.H,t.S,t.z)},
qB(a,b,c){return 0},
iz(a){var s
if(t.Q.b(a)){s=a.gbI()
if(s!=null)return s}return B.av},
td(a,b){var s=new A.ad($.V,b.i("ad<0>"))
A.wj(new A.ji(a,s))
return s},
te(a,b){var s,r,q,p,o,n,m,l,k,j,i,h={},g=null,f=!1,e=new A.ad($.V,b.i("ad<t<0>>"))
h.a=null
h.b=0
h.c=h.d=null
s=new A.jk(h,g,f,e)
try{for(n=a.length,m=t.P,l=0,k=0;l<a.length;a.length===n||(0,A.n)(a),++l){r=a[l]
q=k
r.cI(new A.jj(h,q,e,b,g,f),s,m)
k=++h.b}if(k===0){n=e
n.c8(A.a([],b.i("C<0>")))
return n}h.a=A.a9(k,null,!1,b.i("0?"))}catch(j){p=A.aU(j)
o=A.bP(j)
if(h.b===0||f){n=e
m=p
k=o
i=A.pi(m,k)
if(i==null)m=new A.aK(m,k==null?A.iz(m):k)
else m=i
n.c5(m)
return n}else{h.d=p
h.c=o}}return e},
pi(a,b){var s,r,q,p=$.V
if(p===B.m)return null
s=p.fh(a,b)
if(s==null)return null
r=s.a
q=s.b
if(t.Q.b(r))A.p_(r,q)
return s},
v4(a,b){var s
if($.V!==B.m){s=A.pi(a,b)
if(s!=null)return s}if(b==null)if(t.Q.b(a)){b=a.gbI()
if(b==null){A.p_(a,B.av)
b=B.av}}else b=B.av
else if(t.Q.b(a))A.p_(a,b)
return new A.aK(a,b)},
nw(a,b,c){var s,r,q,p={},o=p.a=a
while(s=o.a,(s&4)!==0){o=o.c
p.a=o}if(o===b){s=A.tN()
b.c5(new A.aK(new A.bz(!0,o,null,"Cannot complete a future with itself"),s))
return}r=b.a&1
s=o.a=s|r
if((s&24)===0){q=b.c
b.a=b.a&1|4
b.c=o
o.eL(q)
return}if(!c)if(b.c==null)o=(s&16)===0||r!==0
else o=!1
else o=!0
if(o){q=b.bV()
b.c6(p.a)
A.cX(b,q)
return}b.a^=2
b.b.bh(new A.nx(p,b))},
cX(a,b){var s,r,q,p,o,n,m,l,k,j,i,h,g={},f=g.a=a
for(;;){s={}
r=f.a
q=(r&16)===0
p=!q
if(b==null){if(p&&(r&1)===0){r=f.c
f.b.dB(r.a,r.b)}return}s.a=b
o=b.a
for(f=b;o!=null;f=o,o=n){f.a=null
A.cX(g.a,f)
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
f.b.dB(r.a,r.b)
return}j=$.V
if(j!==k)$.V=k
else j=null
f=s.a.c
if((f&15)===8)new A.nB(s,g,p).$0()
else if(q){if((f&1)!==0)new A.nA(s,m).$0()}else if((f&2)!==0)new A.nz(g,s).$0()
if(j!=null)$.V=j
f=s.c
if(f instanceof A.ad){r=s.a.$ti
r=r.i("b7<2>").b(f)||!r.y[1].b(f)}else r=!1
if(r){i=s.a.b
if((f.a&24)!==0){h=i.c
i.c=null
b=i.cf(h)
i.a=f.a&30|i.a&1
i.c=f.c
g.a=f
continue}else A.nw(f,i,!0)
return}}i=s.a.b
h=i.c
i.c=null
b=i.cf(h)
f=s.b
r=s.c
if(!f){i.a=8
i.c=r}else{i.a=i.a&1|16
i.c=r}g.a=i
f=i}},
vp(a,b){if(t.ag.b(a))return b.dJ(a,t.z,t.C,t.l)
if(t.bI.b(a))return b.cH(a,t.z,t.C)
throw A.c(A.oB(a,"onError",u.c))},
vj(){var s,r
for(s=$.e0;s!=null;s=$.e0){$.fS=null
r=s.b
$.e0=r
if(r==null)$.fR=null
s.a.$0()}},
vA(){$.pj=!0
try{A.vj()}finally{$.fS=null
$.pj=!1
if($.e0!=null)$.py().$1(A.r_())}},
qX(a){var s=new A.i3(a),r=$.fR
if(r==null){$.e0=$.fR=s
if(!$.pj)$.py().$1(A.r_())}else $.fR=r.b=s},
vx(a){var s,r,q,p=$.e0
if(p==null){A.qX(a)
$.fS=$.fR
return}s=new A.i3(a)
r=$.fS
if(r==null){s.b=p
$.e0=$.fS=s}else{q=r.b
s.b=q
$.fS=r.b=s
if(q==null)$.fR=s}},
wj(a){var s,r=null,q=$.V
if(B.m===q){A.o7(r,r,B.m,a)
return}if(B.m===q.gdl().a)s=B.m.gb3()===q.gb3()
else s=!1
if(s){A.o7(r,r,q,q.cG(a,t.H))
return}s=$.V
s.bh(s.ds(a))},
wI(a){A.cz(a,"stream",t.C)
return new A.ii()},
wi(a,b,c){return A.vw(a,b,null,c)},
vw(a,b,c,d){return $.V.fl(c,b).bG(a,d)},
vt(a,b,c,d,e){A.o4(d,e)},
o4(a,b){A.vx(new A.o5(a,b))},
o6(a,b,c,d){var s,r=$.V
if(r===c)return d.$0()
$.V=c
s=r
try{r=d.$0()
return r}finally{$.V=s}},
po(a,b,c,d,e){var s,r=$.V
if(r===c)return d.$1(e)
$.V=c
s=r
try{r=d.$1(e)
return r}finally{$.V=s}},
pn(a,b,c,d,e,f){var s,r=$.V
if(r===c)return d.$2(e,f)
$.V=c
s=r
try{r=d.$2(e,f)
return r}finally{$.V=s}},
qU(a,b,c,d){return d},
qV(a,b,c,d){return d},
qT(a,b,c,d){return d},
vs(a,b,c,d,e){return null},
o7(a,b,c,d){var s,r
if(B.m!==c){s=B.m.gb3()
r=c.gb3()
d=s!==r?c.ds(d):c.dr(d,t.H)}A.qX(d)},
vr(a,b,c,d,e){return A.qp(d,B.m!==c?c.dr(e,t.H):e)},
vq(a,b,c,d,e){var s
if(B.m!==c)e=c.fa(e,t.H,t.dn)
s=B.c.a3(d.a,1000)
return A.ur(s<0?0:s,e)},
vu(a,b,c,d){A.op(d)},
vn(a){$.V.ft(a)},
qS(a,b,c,d,e){var s,r,q
$.pk=A.vJ()
if(d==null)d=B.dm
if(e==null)s=c.gey()
else{r=t.X
s=A.tf(e,r,r)}r=new A.i6(c.geT(),c.geV(),c.geU(),c.geQ(),c.geR(),c.geP(),c.gec(),c.gdl(),c.ge7(),c.ge6(),c.geM(),c.gel(),c.gd5(),c,s)
q=d.a
if(q!=null)r.as=new A.aT(r,q)
return r},
ni:function ni(a){this.a=a},
nh:function nh(a,b,c){this.a=a
this.b=b
this.c=c},
nj:function nj(a){this.a=a},
nk:function nk(a){this.a=a},
im:function im(){this.c=0},
nS:function nS(a,b){this.a=a
this.b=b},
nR:function nR(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
i2:function i2(a,b){this.a=a
this.b=!1
this.$ti=b},
o_:function o_(a){this.a=a},
o0:function o0(a){this.a=a},
ob:function ob(a){this.a=a},
ca:function ca(a,b){var _=this
_.a=a
_.e=_.d=_.c=_.b=null
_.$ti=b},
cx:function cx(a,b){this.a=a
this.$ti=b},
aK:function aK(a,b){this.a=a
this.b=b},
fu:function fu(){},
fs:function fs(a,b){var _=this
_.b=a
_.c=0
_.e=_.d=null
_.$ti=b},
ji:function ji(a,b){this.a=a
this.b=b},
jk:function jk(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
jj:function jj(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f},
i4:function i4(){},
ft:function ft(a,b){this.a=a
this.$ti=b},
dY:function dY(a,b,c,d,e){var _=this
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
nt:function nt(a,b){this.a=a
this.b=b},
ny:function ny(a,b){this.a=a
this.b=b},
nx:function nx(a,b){this.a=a
this.b=b},
nv:function nv(a,b){this.a=a
this.b=b},
nu:function nu(a,b){this.a=a
this.b=b},
nB:function nB(a,b,c){this.a=a
this.b=b
this.c=c},
nC:function nC(a,b){this.a=a
this.b=b},
nD:function nD(a){this.a=a},
nA:function nA(a,b){this.a=a
this.b=b},
nz:function nz(a,b){this.a=a
this.b=b},
i3:function i3(a){this.a=a
this.b=null},
i8:function i8(){},
i7:function i7(){},
ii:function ii(){},
aT:function aT(a,b){this.a=a
this.b=b},
ip:function ip(){},
i6:function i6(a,b,c,d,e,f,g,h,i,j,k,l,m,n,o){var _=this
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
no:function no(a,b,c){this.a=a
this.b=b
this.c=c},
np:function np(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
nn:function nn(a,b){this.a=a
this.b=b},
ih:function ih(){},
nP:function nP(a,b,c){this.a=a
this.b=b
this.c=c},
nQ:function nQ(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
nO:function nO(a,b){this.a=a
this.b=b},
e_:function e_(a){this.a=a},
o5:function o5(a,b){this.a=a
this.b=b},
iq:function iq(a,b,c,d,e,f,g,h,i,j,k,l,m){var _=this
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
pV(a,b){return new A.fx(a.i("@<0>").au(b).i("fx<1,2>"))},
p7(a,b){var s=a[b]
return s===a?null:s},
p9(a,b,c){if(c==null)a[b]=a
else a[b]=c},
p8(){var s=Object.create(null)
A.p9(s,"<non-identifier-key>",s)
delete s["<non-identifier-key>"]
return s},
c2(a,b){return new A.c0(a.i("@<0>").au(b).i("c0<1,2>"))},
a7(a,b,c){return A.w5(a,new A.c0(b.i("@<0>").au(c).i("c0<1,2>")))},
o(a,b){return new A.c0(a.i("@<0>").au(b).i("c0<1,2>"))},
oU(a){return new A.d0(a.i("d0<0>"))},
aD(a){return new A.d0(a.i("d0<0>"))},
pa(){var s=Object.create(null)
s["<non-identifier-key>"]=s
delete s["<non-identifier-key>"]
return s},
fz(a,b,c){var s=new A.c9(a,b,c.i("c9<0>"))
s.c=a.e
return s},
tf(a,b,c){var s=A.pV(b,c)
a.a1(0,new A.jw(s,b,c))
return s},
Z(a,b,c){var s=A.c2(b,c)
a.a1(0,new A.lR(s,b,c))
return s},
q5(a,b,c){var s=A.c2(b,c)
s.X(0,a)
return s},
ts(a,b){var s,r=A.oU(b)
for(s=J.au(a);s.p();)r.R(0,b.a(s.gF()))
return r},
oV(a,b){var s=A.oU(b)
s.X(0,a)
return s},
oW(a){var s,r
if(A.pt(a))return"{...}"
s=new A.cr("")
try{r={}
$.d5.push(a)
s.a+="{"
r.a=!0
a.a1(0,new A.lT(r,s))
s.a+="}"}finally{$.d5.pop()}r=s.a
return r.charCodeAt(0)==0?r:r},
uB(){throw A.c(A.Y("Cannot change an unmodifiable set"))},
fx:function fx(a){var _=this
_.a=0
_.e=_.d=_.c=_.b=null
_.$ti=a},
nE:function nE(a){this.a=a},
cY:function cY(a,b){this.a=a
this.$ti=b},
fy:function fy(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.d=null
_.$ti=c},
d0:function d0(a){var _=this
_.a=0
_.f=_.e=_.d=_.c=_.b=null
_.r=0
_.$ti=a},
nL:function nL(a){this.a=a
this.c=this.b=null},
c9:function c9(a,b,c){var _=this
_.a=a
_.b=b
_.d=_.c=null
_.$ti=c},
jw:function jw(a,b,c){this.a=a
this.b=b
this.c=c},
lR:function lR(a,b,c){this.a=a
this.b=b
this.c=c},
a2:function a2(){},
aa:function aa(){},
lS:function lS(a){this.a=a},
lT:function lT(a,b){this.a=a
this.b=b},
fA:function fA(a,b){this.a=a
this.$ti=b},
fB:function fB(a,b,c){var _=this
_.a=a
_.b=b
_.c=null
_.$ti=c},
c5:function c5(){},
fH:function fH(){},
io:function io(){},
fm:function fm(a,b){this.a=a
this.$ti=b},
fO:function fO(){},
vl(a,b){var s,r,q,p=null
try{p=JSON.parse(a)}catch(r){s=A.aU(r)
q=A.cj(String(s),null,null)
throw A.c(q)}q=A.o1(p)
return q},
o1(a){var s
if(a==null)return null
if(typeof a!="object")return a
if(!Array.isArray(a))return new A.ib(a,Object.create(null))
for(s=0;s<a.length;++s)a[s]=A.o1(a[s])
return a},
uD(a,b,c){var s,r,q,p=c-b
if(p<=4096)s=$.rA()
else s=new Uint8Array(p)
for(r=0;r<p;++r){q=a[b+r]
if((q&255)!==q)q=255
s[r]=q}return s},
uC(a,b,c,d){var s=a?$.rz():$.ry()
if(s==null)return null
if(0===c&&d===b.length)return A.qH(s,b)
return A.qH(s,b.subarray(c,d))},
qH(a,b){var s,r
try{s=a.decode(b)
return s}catch(r){}return null},
q3(a,b,c){return new A.eF(a,b)},
uU(a){return a.am()},
ub(a,b){return new A.nI(a,[],A.vZ())},
uc(a,b,c){var s,r=new A.cr(""),q=A.ub(r,b)
q.cK(a)
s=r.a
return s.charCodeAt(0)==0?s:s},
uE(a){switch(a){case 65:return"Missing extension byte"
case 67:return"Unexpected extension byte"
case 69:return"Invalid UTF-8 byte"
case 71:return"Overlong encoding"
case 73:return"Out of unicode range"
case 75:return"Encoded surrogate"
case 77:return"Unfinished UTF-8 octet sequence"
default:return""}},
ib:function ib(a,b){this.a=a
this.b=b
this.c=null},
nH:function nH(a){this.a=a},
ic:function ic(a){this.a=a},
nX:function nX(){},
nW:function nW(){},
h3:function h3(){},
h6:function h6(){},
j3:function j3(){},
eF:function eF(a,b){this.a=a
this.b=b},
ht:function ht(a,b){this.a=a
this.b=b},
lN:function lN(){},
lP:function lP(a){this.b=a},
lO:function lO(a){this.a=a},
nJ:function nJ(){},
nK:function nK(a,b){this.a=a
this.b=b},
nI:function nI(a,b,c){this.c=a
this.a=b
this.b=c},
nb:function nb(){},
nc:function nc(){},
nY:function nY(a){this.b=0
this.c=a},
hX:function hX(a){this.a=a},
d2:function d2(a){this.a=a
this.b=16
this.c=0},
d8(a){var s=A.a3(a,null)
if(s!=null)return s
throw A.c(A.cj(a,null,null))},
cA(a){var s=A.aH(a)
if(s!=null)return s
throw A.c(A.cj("Invalid double",a,null))},
t4(a,b){a=A.aC(a,new Error())
a.stack=b.l(0)
throw a},
a9(a,b,c,d){var s,r=c?J.oP(a,d):J.q0(a,d)
if(a!==0&&b!=null)for(s=0;s<r.length;++s)r[s]=b
return r},
a6(a,b,c){var s,r=A.a([],c.i("C<0>"))
for(s=J.au(a);s.p();)r.push(s.gF())
if(b)return r
r.$flags=1
return r},
r(a,b){var s,r
if(Array.isArray(a))return A.a(a.slice(0),b.i("C<0>"))
s=A.a([],b.i("C<0>"))
for(r=J.au(a);r.p();)s.push(r.gF())
return s},
q6(a,b){var s=A.a6(a,!1,b)
s.$flags=3
return s},
tO(a,b,c){var s,r
A.eX(b,"start")
s=c-b
if(s<0)throw A.c(A.ax(c,b,null,"end",null))
if(s===0)return""
r=A.tP(a,b,c)
return r},
tP(a,b,c){var s=a.length
if(b>=s)return""
return A.tC(a,b,c==null||c>s?s:c)},
aI(a,b){return new A.dA(a,A.oQ(a,!1,b,!1,!1,""))},
p4(a,b,c){var s=J.au(b)
if(!s.p())return a
if(c.length===0){do a+=A.D(s.gF())
while(s.p())}else{a+=A.D(s.gF())
while(s.p())a=a+c+A.D(s.gF())}return a},
tN(){return A.bP(new Error())},
t0(a,b,c,d,e,f,g,h,i){var s=A.tD(a,b,c,d,e,f,g,h,i)
if(s==null)return null
return new A.aw(A.oE(s,h,i),h,i)},
t2(a){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c=$.ri().bp(a)
if(c!=null){s=new A.iX()
r=c.b
q=r[1]
q.toString
p=A.d8(q)
q=r[2]
q.toString
o=A.d8(q)
q=r[3]
q.toString
n=A.d8(q)
m=s.$1(r[4])
l=s.$1(r[5])
k=s.$1(r[6])
j=new A.iY().$1(r[7])
i=B.c.a3(j,1000)
h=r[8]!=null
if(h){g=r[9]
if(g!=null){f=g==="-"?-1:1
q=r[10]
q.toString
e=A.d8(q)
l-=f*(s.$1(r[11])+60*e)}}d=A.t0(p,o,n,m,l,k,i,j%1000,h)
if(d==null)throw A.c(A.cj("Time out of range",a,null))
return d}else throw A.c(A.cj("Invalid date format",a,null))},
bA(a){var s,r
try{s=A.t2(a)
return s}catch(r){if(A.aU(r) instanceof A.hg)return null
else throw r}},
oE(a,b,c){var s="microsecond"
if(b<0||b>999)throw A.c(A.ax(b,0,999,s,null))
if(a<-864e13||a>864e13)throw A.c(A.ax(a,-864e13,864e13,"millisecondsSinceEpoch",null))
if(a===864e13&&b!==0)throw A.c(A.oB(b,s,"Time including microseconds is outside valid range"))
A.cz(c,"isUtc",t.y)
return a},
pO(a){var s=Math.abs(a),r=a<0?"-":""
if(s>=1000)return""+a
if(s>=100)return r+"0"+s
if(s>=10)return r+"00"+s
return r+"000"+s},
t1(a){var s=Math.abs(a),r=a<0?"-":"+"
if(s>=1e5)return r+s
return r+"0"+s},
iW(a){if(a>=100)return""+a
if(a>=10)return"0"+a
return"00"+a},
bU(a){if(a>=10)return""+a
return"0"+a},
j2(a,b){return new A.bW(b+864e8*a)},
hc(a){if(typeof a=="number"||A.fP(a)||a==null)return J.x(a)
if(typeof a=="string")return JSON.stringify(a)
return A.qe(a)},
t5(a,b){A.cz(a,"error",t.C)
A.cz(b,"stackTrace",t.l)
A.t4(a,b)},
e8(a){return new A.h_(a)},
bl(a,b){return new A.bz(!1,null,b,a)},
oB(a,b,c){return new A.bz(!0,a,b,c)},
qg(a){var s=null
return new A.dO(s,s,!1,s,s,a)},
mG(a,b){return new A.dO(null,null,!0,a,b,"Value not in range")},
ax(a,b,c,d,e){return new A.dO(b,c,!0,a,d,"Invalid value")},
tG(a,b,c,d){if(a<b||a>c)throw A.c(A.ax(a,b,c,d,null))
return a},
c4(a,b,c){if(0>a||a>c)throw A.c(A.ax(a,0,c,"start",null))
if(b!=null){if(a>b||b>c)throw A.c(A.ax(b,a,c,"end",null))
return b}return c},
eX(a,b){if(a<0)throw A.c(A.ax(a,0,null,b,null))
return a},
oN(a,b,c,d){return new A.hl(b,!0,a,d,"Index out of range")},
Y(a){return new A.fn(a)},
qs(a){return new A.hT(a)},
fg(a){return new A.cq(a)},
aA(a){return new A.h5(a)},
q(a){return new A.nr(a)},
cj(a,b,c){return new A.hg(a,b,c)},
tl(a,b,c){var s,r
if(A.pt(a)){if(b==="("&&c===")")return"(...)"
return b+"..."+c}s=A.a([],t.s)
$.d5.push(a)
try{A.vh(a,s)}finally{$.d5.pop()}r=A.p4(b,s,", ")+c
return r.charCodeAt(0)==0?r:r},
oO(a,b,c){var s,r
if(A.pt(a))return b+"..."+c
s=new A.cr(b)
$.d5.push(a)
try{r=s
r.a=A.p4(r.a,a,", ")}finally{$.d5.pop()}s.a+=c
r=s.a
return r.charCodeAt(0)==0?r:r},
vh(a,b){var s,r,q,p,o,n,m,l=a.gI(a),k=0,j=0
for(;;){if(!(k<80||j<3))break
if(!l.p())return
s=A.D(l.gF())
b.push(s)
k+=s.length+2;++j}if(!l.p()){if(j<=5)return
r=b.pop()
q=b.pop()}else{p=l.gF();++j
if(!l.p()){if(j<=4){b.push(A.D(p))
return}r=A.D(p)
q=b.pop()
k+=r.length+2}else{o=l.gF();++j
for(;l.p();p=o,o=n){n=l.gF();++j
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
wf(a){var s=A.ra(a)
if(s!=null)return s
throw A.c(A.cj(a,null,null))},
ra(a){var s=B.a.W(a),r=A.a3(s,null)
return r==null?A.aH(s):r},
q7(a,b,c,d){var s
if(B.V===c){s=B.c.gY(a)
b=J.by(b)
return A.p5(A.ct(A.ct($.ov(),s),b))}if(B.V===d){s=B.c.gY(a)
b=J.by(b)
c=J.by(c)
return A.p5(A.ct(A.ct(A.ct($.ov(),s),b),c))}s=B.c.gY(a)
b=J.by(b)
c=J.by(c)
d=J.by(d)
d=A.p5(A.ct(A.ct(A.ct(A.ct($.ov(),s),b),c),d))
return d},
cd(a){var s=$.pk
if(s==null)A.op(a)
else s.$1(a)},
aw:function aw(a,b,c){this.a=a
this.b=b
this.c=c},
iX:function iX(){},
iY:function iY(){},
bW:function bW(a){this.a=a},
nq:function nq(){},
ah:function ah(){},
h_:function h_(a){this.a=a},
c7:function c7(){},
bz:function bz(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
dO:function dO(a,b,c,d,e,f){var _=this
_.e=a
_.f=b
_.a=c
_.b=d
_.c=e
_.d=f},
hl:function hl(a,b,c,d,e){var _=this
_.f=a
_.a=b
_.b=c
_.c=d
_.d=e},
fn:function fn(a){this.a=a},
hT:function hT(a){this.a=a},
cq:function cq(a){this.a=a},
h5:function h5(a){this.a=a},
hA:function hA(){},
ff:function ff(){},
nr:function nr(a){this.a=a},
hg:function hg(a,b,c){this.a=a
this.b=b
this.c=c},
F:function F(){},
aj:function aj(a,b,c){this.a=a
this.b=b
this.$ti=c},
aE:function aE(){},
A:function A(){},
il:function il(a){this.a=a},
bK:function bK(){this.b=this.a=0},
cr:function cr(a){this.a=a},
u_(a,b){throw A.c(A.Y("Directory._createTemp"))},
u3(a){throw A.c(A.Y("Directory._systemTemp"))},
u1(a,b){throw A.c(A.Y("Directory._exists"))},
tZ(a,b){throw A.c(A.Y("Directory._create"))},
u0(a,b,c){throw A.c(A.Y("Directory._deleteNative"))},
u2(a,b,c,d,e){throw A.c(A.Y("Directory._fillWithDirectoryListing"))},
u7(a,b){throw A.c(A.Y("File._exists"))},
u4(a,b,c){throw A.c(A.Y("File._create"))},
u5(a,b){throw A.c(A.Y("File._deleteNative"))},
ua(a,b,c){throw A.c(A.Y("File._rename"))},
u9(a,b,c){throw A.c(A.Y("File._open"))},
bN(){throw A.c(A.Y("_Namespace"))},
ud(){throw A.c(A.Y("_Namespace"))},
uk(){throw A.c(A.Y("Platform._numberOfProcessors"))},
um(){throw A.c(A.Y("Platform._pathSeparator"))},
ul(){throw A.c(A.Y("Platform._operatingSystem"))},
tF(){throw A.c(A.Y("ProcessInfo.currentRss"))},
uT(a,b,c){var s
if(t.j.b(a)&&!J.az(J.a_(a,0),0)){s=J.X(a)
switch(s.h(a,0)){case 1:throw A.c(A.bl(b+": "+c,null))
case 2:throw A.c(A.t7(new A.lZ(A.is(s.h(a,2)),A.qK(s.h(a,1))),b,c))
case 3:throw A.c(A.pQ("File closed",c,null))
default:throw A.c(A.e8("Unknown error"))}}},
dq(a){var s
A.oM()
s=A.oG(B.x.aC(a))
return new A.fv(a,s)},
t3(){A.oM()
var s=A.dq(A.u3(A.bN()))
return s},
he(a){var s
A.oM()
s=A.oG(B.x.aC(a))
return new A.fw(a,s)},
pQ(a,b,c){return new A.dt(a,b,c)},
t7(a,b,c){if($.fW())switch(a.b){case 5:case 16:case 19:case 24:case 32:case 33:case 65:case 108:return new A.hF(b,c,a)
case 80:case 183:return new A.hG(b,c,a)
case 2:case 3:case 15:case 123:case 18:case 53:case 67:case 161:case 206:return new A.hH(b,c,a)
default:return new A.dt(b,c,a)}else switch(a.b){case 1:case 13:return new A.hF(b,c,a)
case 17:return new A.hG(b,c,a)
case 2:return new A.hH(b,c,a)
default:return new A.dt(b,c,a)}},
u8(){return A.ud()},
u6(a,b){b[0]=A.u8()},
oG(a){var s,r,q=a.length
if(q!==0)s=B.j.gV(a)!==0
else s=!0
if(s){r=new Uint8Array(q+1)
B.j.a8(r,0,q,a)
return r}else return a},
oH(a){var s,r
if($.fW())if(B.a.U(a,$.rj())){s=B.a.fm(a,A.aI("[/\\\\]",!0),2)
if(s===-1)return a}else s=B.a.U(a,"\\")||B.a.U(a,"/")?0:-1
else s=B.a.U(a,"/")?0:-1
r=B.a.iV(a,$.rk())
if(r>s)return B.a.O(a,0,r+1)
else if(s>-1)return B.a.O(a,0,s+1)
else return"."},
t6(a){var s
if(a.length===0)a="."
if($.fW())for(;;){s=$.ot()
if(!(!B.a.B(a,s)&&!B.a.B(a,"/")))break
a+=A.D(s)}else while(s=$.ot(),!B.a.B(a,s))a+=A.D(s)
return a},
oM(){var s=$.V.h(0,$.rB())
return s==null?null:s},
un(){return A.uk()},
up(){return A.um()},
uo(){return A.ul()},
lZ:function lZ(a,b){this.a=a
this.b=b},
fv:function fv(a,b){this.a=a
this.b=b},
cI:function cI(a){this.a=a},
dt:function dt(a,b,c){this.a=a
this.b=b
this.c=c},
hF:function hF(a,b,c){this.a=a
this.b=b
this.c=c},
hG:function hG(a,b,c){this.a=a
this.b=b
this.c=c},
hH:function hH(a,b,c){this.a=a
this.b=b
this.c=c},
fw:function fw(a,b){this.a=a
this.b=b},
ns:function ns(a){this.a=a},
ds:function ds(){},
tc(a){var s,r=v.G.Promise,q=new A.jh(a)
if(typeof q=="function")A.ap(A.bl("Attempting to rewrap a JS function.",null))
s=function(b,c){return function(d,e){return b(c,d,e,arguments.length)}}(A.uS,q)
s[$.os()]=q
return new r(s)},
jh:function jh(a){this.a=a},
jf:function jf(a){this.a=a},
jg:function jg(a){this.a=a},
nF:function nF(){},
id:function id(){this.b=this.a=0},
aq(a,b,c){var s=a.BYTES_PER_ELEMENT
c=A.c4(b,c,B.c.aY(a.byteLength,s))
return J.rK(B.j.gai(a),a.byteOffset+b*s,(c-b)*s)},
pW(a,b,c){var s=a.BYTES_PER_ELEMENT,r=(A.c4(b,c,B.c.aY(a.byteLength,s))-b)*s
if(B.c.a7(r,4)!==0)throw A.c(A.bl("The number of bytes to view must be a multiple of 4",null))
return J.rM(B.E.gai(a),a.byteOffset+b*s,B.c.a3(r,4))},
pT(a,b,c){var s=a.BYTES_PER_ELEMENT,r=(A.c4(b,c,B.c.aY(a.byteLength,s))-b)*s
if(B.c.a7(r,8)!==0)throw A.c(A.bl("The number of bytes to view must be a multiple of 8",null))
return J.rL(B.ab.gai(a),a.byteOffset+b*s,B.c.a3(r,8))},
j4:function j4(){},
pH(a){var s,r,q,p,o,n=new Uint8Array(32),m=a.length
if(m===32)B.j.aj(n,0,a)
else for(s=m===0,r=0;r<32;++r)n[r]=s?0:(a[B.c.a7(r,m)]^r*17)>>>0
q=new Uint32Array(60)
for(r=0;r<8;++r){m=r*4
q[r]=(n[m]<<24|n[m+1]<<16|n[m+2]<<8|n[m+3])>>>0}p=[0,1,2,4,8,16,32,64,128,27,54]
for(r=8;r<60;++r){o=q[r-1]
m=B.c.a7(r,8)
if(m===0){o=o<<8|o>>>24
o=($.cD[o>>>24&255]<<24|$.cD[o>>>16&255]<<16|$.cD[o>>>8&255]<<8|$.cD[o&255])^p[B.c.a3(r,8)]<<24}else if(m===4)o=$.cD[o>>>24&255]<<24|$.cD[o>>>16&255]<<16|$.cD[o>>>8&255]<<8|$.cD[o&255]
q[r]=(q[r-8]^o)>>>0}return q},
fY:function fY(a){this.a=a},
fZ:function fZ(a){this.a=a},
pP(){return new A.j5()},
j5:function j5(){},
q8(a,b){var s=new Uint8Array(b),r=new A.dI(a,s)
r.c=A.aq(s,0,null)
return r},
dI:function dI(a,b){var _=this
_.a=a
_.b=b
_.c=$
_.d=!1
_.e=0
_.r=-1
_.x=_.w=null},
oY(a,b,c){var s=t.L,r=t.N,q=t.S,p=A.a([],t.ei),o=A.a7([0,B.U],q,t.ch)
A.pP()
return new A.m_(b,a,A.o(s,t.b7),A.aD(s),A.o(r,t.d9),A.o(r,t.p),A.o(r,q),p,new A.cS(),new A.lV(o,A.aD(q)),!0)},
aV(a){var s=A.aq(a,0,null)
return new A.cm(s.getUint32(0,!1),s.getUint32(4,!1),s.getUint32(8,!1),J.bk(B.j.gai(a),a.byteOffset+12,a.length-12))},
ao:function ao(a,b){this.a=a
this.b=b},
dJ:function dJ(a,b,c){var _=this
_.a=a
_.b=null
_.c=b
_.d=-1
_.e=null
_.f=$
_.r=c},
mb:function mb(){},
mc:function mc(a){this.a=a},
hB:function hB(a){this.a=a},
hO:function hO(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
n5:function n5(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=null
_.e=d},
cS:function cS(){this.c=this.b=this.a=null},
m_:function m_(a,b,c,d,e,f,g,h,i,j,k){var _=this
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
m0:function m0(a){this.a=a},
m3:function m3(a){this.a=a},
m9:function m9(a){this.a=a},
ma:function ma(a){this.a=a},
m8:function m8(a,b,c){this.a=a
this.b=b
this.c=c},
m1:function m1(a,b){this.a=a
this.b=b},
m7:function m7(a,b){this.a=a
this.b=b},
m2:function m2(a,b,c){this.a=a
this.b=b
this.c=c},
m5:function m5(){},
m6:function m6(){},
m4:function m4(a){this.a=a},
dV:function dV(a,b){this.a=a
this.b=b},
lU:function lU(a,b){this.a=a
this.b=b},
lV:function lV(a,b){this.a=1
this.b=a
this.c=b},
cm:function cm(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
oD(a,b){var s,r=t.N,q=new A.h8(a,A.o(r,t.fr),A.o(r,t.gc),A.o(r,t.aW),A.o(r,t.da),A.a7(["main",A.aD(r)],r,t.cq))
q.f=A.pP()
r=new A.iB(a,A.o(r,t.eT),A.o(r,t.fM),A.o(r,t._),A.o(r,t.h2),A.o(r,t.b0),A.o(r,t.dT),A.o(r,t.eO),A.o(r,t.d5),A.o(r,t.f6))
q.b=r
s=A.oY(a,1000,!0)
q.c=s
q.d=new A.mo(r,s,a,q.gfH())
q.e=new A.iA(a)
return q},
v_(a){var s,r
for(s=a.length,r=0;r<s;++r)if(A.pg(a[r].a))return!0
return!1},
pg(a){var s
if(a instanceof A.af){s=a.b.toLowerCase()
if(s==="count"||s==="sum"||s==="avg"||s==="min"||s==="max")return!0}if(a instanceof A.a0)return A.pg(a.c)||A.pg(a.d)
return!1},
vm(a){var s,r,q,p,o,n,m=B.a.W(a)
if(B.a.U(m,"[")&&B.a.B(m,"]")){s=B.a.W(B.a.O(m,1,m.length-1))
if(J.O(s)===0)return new A.a5(A.a([],t.n))
try{q=J.oz(s,",")
p=A.z(q).i("h<1,W>")
o=A.r(new A.h(q,new A.o3(),p),p.i("u.E"))
r=o
return new A.a5(r)}catch(n){return null}}return null},
v0(a,b,c,d,e,f){var s,r,q,p,o,n,m,l,k,j,i
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
pl(a,b,c,d,e,f){var s,r,q,p,o,n,m,l,k,j,i,h,g
if(e>=f)return
if(f-e<=15){A.v0(a,b,c,d,e,f)
return}s=B.c.bW(e+f,1)
if(b[a[e]]>b[a[s]])A.fT(a,e,s)
if(b[a[e]]>b[a[f]])A.fT(a,e,f)
if(b[a[s]]>b[a[f]])A.fT(a,s,f)
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
a[m]=h;++l;--m}}if(e<m)A.pl(a,b,c,d,e,m)
if(l<f)A.pl(a,b,c,d,l,f)},
pm(a,b,c,d,e,f,g){var s,r,q,p,o,n,m
if(f>=g)return
s=B.c.bW(f+g,1)
if(A.it(a[f],a[s],b,c,d,e)>0)A.fT(a,f,s)
if(A.it(a[f],a[g],b,c,d,e)>0)A.fT(a,f,g)
if(A.it(a[s],a[g],b,c,d,e)>0)A.fT(a,s,g)
r=a[s]
for(q=a.$flags|0,p=g,o=f;o<=p;){while(A.it(a[o],r,b,c,d,e)<0)++o
while(A.it(a[p],r,b,c,d,e)>0)--p
if(o<=p){n=a[o]
m=a[p]
q&2&&A.i(a)
a[o]=m
a[p]=n;++o;--p}}if(f<p)A.pm(a,b,c,d,e,f,p)
if(o<g)A.pm(a,b,c,d,e,o,g)},
it(a,b,c,d,e,f){var s,r,q,p,o
for(s=a*f,r=b*f,q=0;q<f;++q){p=B.h.A(c[s+q],c[r+q])
if(p!==0)return p}o=B.c.A(d[a],d[b])
if(o!==0)return o
return B.c.A(e[a],e[b])},
fT(a,b,c){var s=a[b],r=a[c]
a.$flags&2&&A.i(a)
a[b]=r
a[c]=s},
B:function B(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
mF:function mF(){},
h8:function h8(a,b,c,d,e,f){var _=this
_.a=a
_.f=_.e=_.d=_.c=_.b=$
_.r=b
_.w=c
_.x=d
_.y=e
_.Q=f},
iV:function iV(){},
jO:function jO(a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q){var _=this
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
jT:function jT(a){this.a=a},
jS:function jS(a){this.a=a},
jY:function jY(){},
jZ:function jZ(){},
k_:function k_(){},
k0:function k0(){},
k1:function k1(){},
k2:function k2(){},
k3:function k3(){},
k4:function k4(){},
k5:function k5(){},
jU:function jU(){},
jV:function jV(){},
jX:function jX(a){this.a=a},
kB:function kB(a){this.a=a},
kg:function kg(a,b){this.a=a
this.b=b},
kh:function kh(a){this.a=a},
kf:function kf(){},
ki:function ki(a,b){this.a=a
this.b=b},
kj:function kj(a,b){this.a=a
this.b=b},
kk:function kk(a,b){this.a=a
this.b=b},
kl:function kl(a,b){this.a=a
this.b=b},
km:function km(a,b){this.a=a
this.b=b},
kn:function kn(a){this.a=a},
k7:function k7(a,b){this.a=a
this.b=b},
k8:function k8(a){this.a=a},
k9:function k9(a){this.a=a},
ka:function ka(a){this.a=a},
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
jP:function jP(a,b){this.a=a
this.b=b},
ku:function ku(a){this.a=a},
kv:function kv(a){this.a=a},
kw:function kw(){},
kz:function kz(){},
kx:function kx(a,b,c){this.a=a
this.b=b
this.c=c},
ky:function ky(){},
jR:function jR(a){this.a=a},
k6:function k6(a){this.a=a},
kA:function kA(a){this.a=a},
jW:function jW(){},
kr:function kr(a){this.a=a},
ks:function ks(a){this.a=a},
kt:function kt(a){this.a=a},
kd:function kd(a){this.a=a},
ke:function ke(a){this.a=a},
kM:function kM(a){this.a=a},
kN:function kN(){},
kO:function kO(){},
kP:function kP(){},
kQ:function kQ(){},
jQ:function jQ(a,b){this.a=a
this.b=b},
kb:function kb(a){this.a=a},
kc:function kc(a){this.a=a},
bu:function bu(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f},
o3:function o3(){},
cw:function cw(a,b,c){this.a=a
this.b=b
this.c=c},
i5:function i5(a,b){var _=this
_.a=a
_.b=b
_.c=!1
_.d=null
_.e=0
_.f=!1},
qY(a){var s,r,q=a.length
for(s=0;s<q;++s){r=a.charCodeAt(s)
if(r>=65&&r<=90)return a.toLowerCase()}return a},
we(a,b){var s,r,q,p,o,n,m
if(!B.a.E(b,"_")&&!B.a.E(b,"\\")){s=B.a.U(b,"%")
r=B.a.B(b,"%")
q=s?1:0
p=b.length
if(!B.a.E(B.a.O(b,q,p-(r?1:0)),"%")){o=A.qY(a)
q=s?1:0
n=B.a.O(b,q,p-(r?1:0)).toLowerCase()
if(s&&r)return B.a.E(o,n)
else if(s)return B.a.B(o,n)
else if(r)return B.a.U(o,n)
else return o===n}}q=A.iv(b)
q=A.S(q,"\\%","%")
q=A.S(q,"\\_","_")
q=A.S(q,"%",".*")
m=A.aI("^"+A.S(q,"_",".")+"$",!1)
return m.b.test(a)},
K(a){var s,r,q={}
if(a instanceof A.ag||a instanceof A.aQ||a instanceof A.cv)return A.c_(a)
s=A.R(a)
r=A.c_(a)
q.a=null
q.b=!1
return new A.lL(q,r,s)},
c_(a){var s,r,q,p,o,n,m,l,k,j,i,h
if(a instanceof A.cs)return new A.la(a)
if(a instanceof A.b9)return new A.lb(A.K(a.b),a.c,a.d)
if(a instanceof A.aQ)return new A.lc(a.c)
if(a instanceof A.ag)return new A.ln(A.cg(a.b))
if(a instanceof A.cv)return new A.ly(new A.a5(a.b))
if(a instanceof A.I){s={}
r=a.b
if(r.length===0)return new A.lD()
q=B.b.S(r,".").toLowerCase()
if(q==="true")return new A.lE()
if(q==="false")return new A.lF()
s.a=s.b=null
s.c=1
return new A.lG(s,r.length>1,r,a)}if(a instanceof A.a0){s=a.c
p=A.c_(s)
o=a.d
n=A.c_(o)
switch(a.b.toLowerCase()){case"+":return new A.lH(p,n)
case"-":return new A.lI(p,n)
case"*":return new A.ld(p,n)
case"/":return new A.le(p,n)
case"%":m=!1
if(s instanceof A.I)if(o instanceof A.I){m=o.b
m=B.b.S(m,".").toLowerCase()==="found"||B.b.S(m,".").toLowerCase()==="notfound"}if(m)return new A.lf((B.b.S(s.b,".")+"%"+B.b.S(o.b,".")).toLowerCase())
return new A.lg(p,n)
case"||":return new A.lh(p,n)
case"=":return new A.li(p,n)
case"!=":case"<>":return new A.lj(p,n)
case"<":return new A.lk(p,n)
case"<=":return new A.ll(p,n)
case">":return new A.lm(p,n)
case">=":return new A.lo(p,n)
case"~":s={}
l=A.c_(o)
s.a=s.b=null
return new A.lp(s,p,l)
case"like":case"ilike":if(o instanceof A.ag||o instanceof A.aQ){s={}
k=s.a=s.b=s.c=null
s.d=s.e=s.f=s.r=!1
s.w=""
return new A.lq(s,o instanceof A.aQ?o.c:k,n,p)}return new A.lr(p,n)
case"in":return new A.ls(p,n)
case"and":return new A.lt(p,n)
case"or":return new A.lu(p,n)
default:return new A.lv()}}if(a instanceof A.dd){s=a.b
o=A.z(s).i("h<1,+condFn,thenFn(k(w<e,k>),k(w<e,k>))>")
j=A.r(new A.h(s,new A.lw(),o),o.i("u.E"))
s=a.c
return new A.lx(j,s!=null?A.c_(s):null)}if(a instanceof A.ce)return new A.lz(A.c_(a.b),a.c)
if(a instanceof A.af){i=A.R(a)
s=a.c
o=A.z(s).i("h<1,k(w<e,k>)>")
h=A.r(new A.h(s,new A.lA(),o),o.i("u.E"))
return new A.lB(i,a.b.toLowerCase(),h,a)}return new A.lC()},
q2(a){var s,r,q,p,o,n,m=B.a.W(a)
if(B.a.U(m,"[")&&B.a.B(m,"]")){s=B.a.W(B.a.O(m,1,m.length-1))
if(J.O(s)===0)return new A.a5(A.a([],t.n))
try{q=J.oz(s,",")
p=A.z(q).i("h<1,W>")
o=A.r(new A.h(q,new A.lK(),p),p.i("u.E"))
r=o
return new A.a5(r)}catch(n){return null}}return null},
oS(a){var s,r,q=A.aI("POINT\\s*\\(\\s*([0-9.-]+)\\s+([0-9.-]+)\\s*\\)",!1).bp(a)
if(q!=null){s=q.b
r=s[1]
r.toString
r=A.cA(r)
s=s[2]
s.toString
return A.a([r,A.cA(s)],t.n)}return null},
tq(a){var s,r,q,p,o,n,m,l,k
if(B.a.U(B.a.W(a),"["))try{s=t.j.a(B.o.ag(a))
r=J.bG(s,new A.lJ(),t.o)
r=A.r(r,r.$ti.i("u.E"))
return r}catch(q){return null}p=A.aI("POLYGON\\s*\\(\\s*\\(([^)]+)\\)\\s*\\)",!1).bp(a)
if(p!=null){o=p.b[1].split(",")
n=A.a([],t.gy)
for(r=o.length,m=t.n,l=0;l<r;++l){k=B.a.cR(B.a.W(o[l]),A.aI("\\s+",!0))
if(k.length>=2)n.push(A.a([A.cA(k[0]),A.cA(k[1])],m))}return n}return null},
lL:function lL(a,b,c){this.a=a
this.b=b
this.c=c},
la:function la(a){this.a=a},
l9:function l9(){},
lb:function lb(a,b,c){this.a=a
this.b=b
this.c=c},
lc:function lc(a){this.a=a},
ln:function ln(a){this.a=a},
ly:function ly(a){this.a=a},
lD:function lD(){},
lE:function lE(){},
lF:function lF(){},
lG:function lG(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
lH:function lH(a,b){this.a=a
this.b=b},
lI:function lI(a,b){this.a=a
this.b=b},
ld:function ld(a,b){this.a=a
this.b=b},
le:function le(a,b){this.a=a
this.b=b},
lf:function lf(a){this.a=a},
lg:function lg(a,b){this.a=a
this.b=b},
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
lo:function lo(a,b){this.a=a
this.b=b},
lp:function lp(a,b,c){this.a=a
this.b=b
this.c=c},
lq:function lq(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
lr:function lr(a,b){this.a=a
this.b=b},
ls:function ls(a,b){this.a=a
this.b=b},
lt:function lt(a,b){this.a=a
this.b=b},
lu:function lu(a,b){this.a=a
this.b=b},
lv:function lv(){},
lw:function lw(){},
lx:function lx(a,b){this.a=a
this.b=b},
lz:function lz(a,b){this.a=a
this.b=b},
lA:function lA(){},
lB:function lB(a,b,c,d){var _=this
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
lC:function lC(){},
lK:function lK(){},
lJ:function lJ(){},
wh(b2){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0=null,b1=A.oY(b0,100,!0)
b1.f=b2.d
p=b2.f
o=p!=null?A.K(p):b0
n=A.a([],t.b)
for(m=b2.b,p=b2.c,l=b2.a,k=b2.r,j=k!=null,i=b2.e,h=i.b,i=i.a+".",g=t.N,f=t.r;m.cN(0,p);m=m.aq(0,1)){e=b1.C(l,m)
d=e.w
if(d==null){c=e.c
c===$&&A.b()
d=e.w=c.getUint16(1,!1)}for(b=0;b<d;++b){s=A.ab(e,b)
if(s!=null){r=null
try{q=A.aV(s)
r=A.a4(q.d,b0,b0)}catch(a){r=A.a4(s,b0,b0)}a0=A.o(g,f)
for(a1=0;a1<h.length;++a1){a0.k(0,h[a1],J.a_(r,a1))
a0.k(0,i+h[a1],J.a_(r,a1))}if(o!=null){a2=o.$1(a0)
if(!(a2 instanceof A.p&&a2.a===1))a3=a2 instanceof A.j&&a2.a>0
else a3=!0
if(!a3)continue}if(j){a4=A.o(g,f)
for(c=k.length,a5=0;a5<k.length;k.length===c||(0,A.n)(k),++a5){a6=k[a5]
a7=a6.a
a8=A.bO(a7,a0)
a9=a6.b
if(a9==null)a9=a7 instanceof A.I?B.b.S(a7.b,"."):a8.l(0)
a4.k(0,a9,a8)}n.push(a4)}else n.push(a0)}}b1.u(l,m,!1)}b1.du()
return n},
wg(c4){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2,b3,b4,b5,b6,b7,b8,b9,c0,c1,c2=null,c3=A.oY(c2,100,!0)
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
for(f=c4.b,h=c4.c,e=c4.a,d=n!=null,c=c4.e,b=c.b,c=c.a+".",a=t.N;f.cN(0,h);f=f.aq(0,1)){a0=c3.C(e,f)
a1=a0.w
if(a1==null){a2=a0.c
a2===$&&A.b()
a1=a0.w=a2.getUint16(1,!1)}for(a3=0;a3<a1;++a3){s=A.ab(a0,a3)
if(s!=null){r=null
try{q=A.aV(s)
r=A.a4(q.d,c2,c2)}catch(a4){r=A.a4(s,c2,c2)}a5=A.o(a,l)
for(a6=0;a6<b.length;++a6){a5.k(0,b[a6],J.a_(r,a6))
a5.k(0,c+b[a6],J.a_(r,a6))}if(o!=null){a7=o.$1(a5)
if(!(a7 instanceof A.p&&a7.a===1))a8=a7 instanceof A.j&&a7.a>0
else a8=!0
if(!a8)continue}if(d){a9=g.J(n.$1(a5),new A.oq(a5))
p.toString
a9.dM(a5,p,m)}else{a9=g.J(A.v(1),new A.or(a5))
p.toString
a9.dM(a5,p,m)}}}c3.u(e,f,!1)}b0=A.a([],t.b)
for(h=new A.am(g,g.$ti.i("am<1,2>")).gI(0);h.p();){b1=h.d
b2=b1.a
a9=b1.b
b3=A.o(a,l)
b3.k(0,"group_key",b2)
for(e=p.length,d=a9.x,c=a9.w,b=a9.r,a2=a9.e,b4=a9.f,b5=a9.d,b6=a9.c,b7=a9.b,k=0;k<p.length;p.length===e||(0,A.n)(p),++k){j=p[k]
i=j.a
b8=j.b
if(b8==null)b8=A.R(i)
if(i instanceof A.af){b9=i.b.toLowerCase()
if(b9==="count"){c0=b7.h(0,b8)
b3.k(0,b8,A.v(c0==null?0:c0))}else if(b9==="sum"){c1=b6.h(0,b8)
if(c1==null)b3.k(0,b8,new A.d())
else{c0=b5.h(0,b8)
b3.k(0,b8,c0===!0?new A.j(c1):A.v(B.h.be(c1)))}}else if(b9==="avg"){c0=b4.h(0,b8)
b3.k(0,b8,new A.j(c0==null?0:c0))
c0=a2.h(0,b8)
b3.k(0,b8+"_count",A.v(c0==null?0:c0))}else if(b9==="min"){c0=b.h(0,b8)
b3.k(0,b8,c0==null?new A.d():c0)}else if(b9==="max"){c0=c.h(0,b8)
b3.k(0,b8,c0==null?new A.d():c0)}else{c0=d.h(0,b8)
b3.k(0,b8,c0==null?new A.d():c0)}}else{c0=d.h(0,b8)
b3.k(0,b8,c0==null?new A.d():c0)}}b0.push(b3)}c3.du()
return b0},
mg:function mg(a,b,c,d,e,f,g,h,i){var _=this
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
dK:function dK(a,b,c,d,e,f,g,h,i){var _=this
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
md:function md(a){this.a=a},
me:function me(a){this.a=a},
mf:function mf(){},
bO(d0,d1){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2,b3,b4,b5,b6,b7,b8,b9,c0,c1,c2,c3,c4,c5,c6,c7=null,c8="euclidean",c9=A.R(d0)
if(d1.D(c9)){j=d1.h(0,c9)
j.toString
return j}for(j=A.E(d1),i=j.i("aL<1>"),h=new A.aL(d1,d1.r,d1.e,i);h.p();){g=h.d
if(g.toLowerCase()===c9.toLowerCase()){j=d1.h(0,g)
j.toString
return j}}if(d0 instanceof A.cs){s=$.cN
if(s==null)return new A.d()
$.cU.push(d1)
try{r=s.aB(d0.b)
if(r!=null){q=r.gfw()
if(t.j.b(q)){if(J.O(q)===0){h=A.a([],t.K)
return new A.aO(h)}if(J.O(q)===1&&J.a_(q,0).length===1){h=J.a_(q,0)[0]
return h}h=q
g=A.z(h).i("h<1,k>")
h=A.r(new A.h(h,new A.oe(),g),g.i("u.E"))
return new A.aO(h)}}return new A.d()}finally{if($.cU.length!==0)$.cU.pop()}}if(d0 instanceof A.b9){f=A.bO(d0.b,d1)
if(f instanceof A.L){e=f.ga2()
if(t.f.b(e))d=e.h(0,d0.c)
else if(t.j.b(e)){c=A.a3(d0.c,c7)
d=c!=null&&c>=0&&c<J.O(e)?J.a_(e,c):c7}else d=c7
if(d==null)return new A.d()
if(d0.d)if(typeof d=="string")return new A.m(d)
else return new A.m(B.o.bC(d))
else if(A.fQ(d))return A.v(d)
else if(typeof d=="number")return new A.j(d)
else if(typeof d=="number")return new A.j(d)
else if(A.fP(d))return A.v(d?1:0)
else return new A.L(d,c7)}return new A.d()}if(d0 instanceof A.aQ)return new A.d()
if(d0 instanceof A.ag)return A.cg(d0.b)
if(d0 instanceof A.cv)return new A.a5(d0.b)
if(d0 instanceof A.I){b=d0.b
if(b.length===0)return new A.d()
a=B.b.S(b,".")
a0=a.toLowerCase()
if(a0==="true")return new A.L(!0,c7)
if(a0==="false")return new A.L(!1,c7)
if(d1.D(a)){j=d1.h(0,a)
j.toString
return j}if(b.length>=2){a1=b[0]+"."+b[1]
if(d1.D(a1)){h=d1.h(0,a1)
h.toString
if(h instanceof A.L)return h.aV(B.b.ac(b,2))}}if(b.length>=2){a2=b[0]
if(d1.D(a2)){h=d1.h(0,a2)
h.toString
if(h instanceof A.L)return h.aV(B.b.ac(b,1))}for(i=new A.aL(d1,d1.r,d1.e,i),h="."+a2;i.p();){g=i.d
if(B.a.B(g,h)){g=d1.h(0,g)
g.toString
if(g instanceof A.L)return g.aV(B.b.ac(b,1))}}}a3=b[0]
for(j=new A.am(d1,j.i("am<1,2>")).gI(0),i="."+a3;j.p();){a4=j.d
a5=a4.a
if(a5===a3||B.a.B(a5,i))return a4.b}a6=A.qm(B.b.S(b,"."))
if(a6!=null)return a6
return new A.d()}if(d0 instanceof A.a0){a7=A.bO(d0.c,d1)
a8=A.bO(d0.d,d1)
switch(d0.b.toLowerCase()){case"+":return a7.aq(0,a8)
case"-":return a7.aH(0,a8)
case"*":return a7.P(0,a8)
case"/":return a7.aE(0,a8)
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
i=A.iv(a8.l(0))
i=A.S(i,"\\%","%")
i=A.S(i,"\\_","_")
i=A.S(i,"%",".*")
a9=A.aI("^"+A.S(i,"_",".")+"$",!1)
return A.v(a9.b.test(j)?1:0)
case"in":if(a8 instanceof A.aO){j=a8.a
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
b4=A.r(new A.h(j,new A.of(d1),i),i.i("u.E"))
if(a3==="in_list")return new A.aO(b4)
i=$.cN
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
p.aB(l)}}catch(b8){j=A.aU(b8)
if(j instanceof A.dQ){k=j
m=k.a}else throw b8}finally{p.c.v(0)
p.c.X(0,n)}return m}}if(a3==="vector_distance"){i=b4.length
i=i===2||i===3}else i=!1
if(i){b9=b4[0]
c0=b4[1]
if(b4.length===3){c1=b4[2]
c2=c1 instanceof A.m?c1.a.toLowerCase():c8}else c2=c8
if(b9 instanceof A.m){c3=A.qR(b9.a)
b9=c3==null?b9:c3}if(c0 instanceof A.m){c4=A.qR(c0.a)
c0=c4==null?c0:c4}if(b9 instanceof A.a5&&c0 instanceof A.a5)switch(c2){case"cosine":return new A.j(b9.cl(c0))
case"dot":return new A.j(b9.cn(c0))
case"euclidean":default:return new A.j(b9.cm(c0))}}if(a3==="cast"&&b4.length===2){c5=b4[0]
c6=J.x(t.gV.a(j[1]).b)
if(c5 instanceof A.d)return new A.d()
if(c6==="DataType.text")return new A.m(c5.l(0))
else if(c6==="DataType.integer"){if(c5 instanceof A.p)return c5
if(c5 instanceof A.j)return A.v(B.h.be(c5.a))
j=A.a3(c5.l(0),c7)
return A.v(j==null?0:j)}else if(c6==="DataType.double"){if(c5 instanceof A.j)return c5
if(c5 instanceof A.p)return new A.j(c5.a)
j=A.aH(c5.l(0))
return new A.j(j==null?0:j)}}if(a3==="json_set"&&b4.length===3)return A.r4(b4[0],b4[1],b4[2])
if(a3==="json_remove"&&b4.length===2)return A.r3(b4[0],b4[1])
if(a3==="json_array")return A.w1(b4)
if(a3==="json_object")return A.w2(b4)
return new A.d()}return new A.d()},
qi(a,b,c,d){var s=new A.f4(a,b,c,d)
s.fU(a,b,c,d)
return s},
pN(a,b,c){var s=new A.h4(a,b,c,A.a([],t.f8),A.o(t.N,t.r))
s.fR(a,b,c)
return s},
tg(a,b,c,d,e,f){var s=new A.eA(f,e,b,c,a,d)
s.fS(a,b,c,d,e,f)
return s},
eu(a,b){var s=new A.ci(a,b)
s.c=A.K(b)
return s},
hK(a,b){var s=new A.co(a,b)
s.fT(a,b)
return s},
oA(a){var s=t.N,r=t.S,q=t.i,p=t.r
A.q5(a,s,p)
return new A.da(A.o(s,r),A.o(s,q),A.o(s,t.y),A.o(s,r),A.o(s,q),A.o(s,p),A.o(s,p),A.o(s,p))},
ql(a,b,c){var s=new A.dS(a,b,c,A.a([],t.b))
s.d=A.K(b)
return s},
qR(a){var s,r,q,p,o,n,m=B.a.W(a)
if(B.a.U(m,"[")&&B.a.B(m,"]")){s=B.a.W(B.a.O(m,1,m.length-1))
if(J.O(s)===0)return new A.a5(A.a([],t.n))
try{q=J.oz(s,",")
p=A.z(q).i("h<1,W>")
o=A.r(new A.h(q,new A.o2(),p),p.i("u.E"))
r=o
return new A.a5(r)}catch(n){return null}}return null},
qN(a,b,c){var s,r,q,p,o,n,m,l,k,j=null
try{s=A.aV(b)
n=a.a
r=n.ga5()
q=n.ax
n=r
m=n==null?j:n.a
p=m==null?0:m
n=r
l=n==null?j:n.b
o=l==null?B.u:l
if(q.aD(s.a,s.b,p,o)){n=A.a4(s.d,c,j)
return n}return j}catch(k){n=A.a4(b,c,j)
return n}},
qt(a,b){var s=new A.hU(a,b,A.aD(t.Y))
s.fW(a,b)
return s},
P:function P(){},
oe:function oe(){},
of:function of(a){this.a=a},
f4:function f4(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=null
_.x=_.w=_.r=_.f=$},
mK:function mK(a){this.a=a},
mL:function mL(a){this.a=a},
dU:function dU(a,b){this.a=a
this.b=b},
hj:function hj(a,b){var _=this
_.a=a
_.b=b
_.c=null
_.d=0},
jd:function jd(a,b){this.a=a
this.b=b},
je:function je(a,b){this.a=a
this.b=b},
hf:function hf(a){this.a=a
this.b=null
this.c=0},
h4:function h4(a,b,c,d,e){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=!1
_.r=_.f=$
_.w=e},
iS:function iS(a){this.a=a},
iT:function iT(a){this.a=a},
iU:function iU(a){this.a=a},
eA:function eA(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=null
_.w=0
_.z=_.y=_.x=null
_.ax=_.at=_.as=_.Q=$},
jL:function jL(a){this.a=a},
jM:function jM(a){this.a=a},
jN:function jN(){},
ci:function ci(a,b){this.a=a
this.b=b
this.c=$},
co:function co(a,b){this.a=a
this.b=b
this.c=$},
mm:function mm(){},
mn:function mn(){},
da:function da(a,b,c,d,e,f,g,h){var _=this
_.b=a
_.c=b
_.d=c
_.e=d
_.f=e
_.r=f
_.w=g
_.x=h},
bY:function bY(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=null
_.f=0},
jq:function jq(){},
jp:function jp(){},
jr:function jr(){},
jo:function jo(){},
js:function js(a,b,c){this.a=a
this.b=b
this.c=c},
jn:function jn(){},
jm:function jm(){},
jt:function jt(){},
dw:function dw(a,b,c,d,e,f,g,h,i,j,k,l){var _=this
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
jv:function jv(){},
ju:function ju(a){this.a=a},
hz:function hz(a,b,c,d,e,f,g,h,i,j){var _=this
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
lX:function lX(a){this.a=a},
dS:function dS(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=$
_.e=d
_.f=0},
mN:function mN(a){this.a=a},
i_:function i_(a,b){var _=this
_.a=a
_.b=b
_.c=null
_.d=0},
nd:function nd(){},
ne:function ne(a){this.a=a},
nf:function nf(){},
ng:function ng(a,b){this.a=a
this.b=b},
hi:function hi(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=null
_.w=0},
dE:function dE(a){this.a=a
this.b=0},
hL:function hL(a,b){var _=this
_.a=a
_.b=b
_.c=null
_.d=0},
mJ:function mJ(a){this.a=a},
cP:function cP(a,b,c){var _=this
_.a=a
_.b=b
_.c=c
_.e=_.d=0},
o2:function o2(){},
dx:function dx(a,b,c,d,e,f,g,h,i,j,k,l){var _=this
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
jJ:function jJ(a){this.a=a},
dv:function dv(a,b,c,d,e,f,g){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g
_.w=$},
jl:function jl(){},
hk:function hk(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.r=f
_.w=null
_.x=0},
jI:function jI(a,b){this.a=a
this.b=b},
hp:function hp(a,b,c,d,e,f){var _=this
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
hU:function hU(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.d=c
_.e=null
_.f=-1},
n9:function n9(a){this.a=a},
na:function na(){},
hn:function hn(a,b){var _=this
_.a=a
_.b=b
_.d=_.c=null
_.e=!1},
kU:function kU(a){this.a=a},
hd:function hd(a,b){var _=this
_.a=a
_.b=b
_.d=_.c=null
_.e=!1},
j6:function j6(a){this.a=a},
h9:function h9(a,b){this.a=a
this.b=b},
pf(a){var s
if(a instanceof A.eI)return a
if(a instanceof A.a0){s=A.pf(a.c)
return s==null?A.pf(a.d):s}return null},
mo:function mo(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
mp:function mp(a){this.a=a},
mr:function mr(){},
mq:function mq(a){this.a=a},
mE:function mE(a){this.a=a},
my:function my(a){this.a=a},
mv:function mv(a){this.a=a},
mz:function mz(){},
mA:function mA(){},
mB:function mB(){},
mC:function mC(a){this.a=a},
mD:function mD(a){this.a=a},
mu:function mu(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
mt:function mt(a){this.a=a},
mw:function mw(a){this.a=a},
mx:function mx(){},
ms:function ms(a,b){this.a=a
this.b=b},
bi:function bi(a,b,c){this.a=a
this.b=b
this.c=c},
jK:function jK(a,b,c){this.a=a
this.b=b
this.c=c},
t8(a){var s,r,q,p=$.oK
if(p!=null)if(p.b==null)p.b=$.bs.$0()
p=$.oK
r=p==null?null:p.gbB()
if(r==null)r=0
$.oJ=!1
s=0
try{s=A.tF()}catch(q){s=0}return new A.j7($.pR,r,a,95,s,A.q6($.pS,t.fU))},
j7:function j7(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f},
j8:function j8(){},
bV(a,b,c){var s,r,q,p,o
if(c===0)return new A.d()
s=b+1
r=c-1
switch(a.getUint8(b)){case 0:return new A.d()
case 1:if(r===1)return A.v(a.getInt8(s))
else if(r===2)return A.v(a.getInt16(s,!1))
else if(r===4)return A.v(a.getInt32(s,!1))
else if(r===8)return A.v(B.r.c0(a,s))
throw A.c(A.cj("Invalid DbInt length: "+r,null,null))
case 2:return new A.j(a.getFloat64(s,!1))
case 3:return new A.m(B.a5.ag(J.bk(B.r.gai(a),a.byteOffset+s,r)))
case 4:q=B.c.a3(r,8)
p=J.dz(q,t.i)
for(o=0;o<q;++o)p[o]=a.getFloat64(s+o*8,!1)
return new A.a5(p)
case 5:return new A.L(null,J.bk(B.r.gai(a),a.byteOffset+s,r))
case 8:return new A.aG(a.getUint8(s)!==0)
case 9:return new A.bn(B.a5.ag(J.bk(B.r.gai(a),a.byteOffset+s,r)))
case 10:B.r.c0(a,s)
return void 1
case 11:return new A.b_(new Uint8Array(A.bx(J.bk(B.r.gai(a),a.byteOffset+s,r))))
case 12:return new A.a8(a.getFloat64(s,!1))
default:return new A.d()}},
cg(a){var s
if(a==null)return new A.d()
if(A.fP(a))return new A.aG(a)
if(a instanceof A.aw)return new A.bm(a)
if(t.p.b(a))return new A.b_(a)
if(A.fQ(a)){if(a>=-100&&a<=1000)return $.px()[a+100]
return A.v(a)}if(typeof a=="number")return new A.j(a)
if(typeof a=="number")return new A.j(a)
if(typeof a=="string")return new A.m(a)
if(t.o.b(a))return new A.a5(a)
if(t.j.b(a)){s=J.bb(a)
if(s.cq(a,new A.j0())){s=s.bd(a,new A.j1(),t.i)
s=A.r(s,s.$ti.i("u.E"))
return new A.a5(s)}return new A.L(a,null)}if(t.f.b(a))return new A.L(a,null)
return new A.m(J.x(a))},
oF(a){return new A.p(a)},
v(a){if(a===0)return $.T()
if(a===1)return $.U()
if(a>=-100&&a<=1000)return $.px()[a+100]
return new A.p(a)},
w4(a3,a4){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2
if(a4.length===0)return new A.L(B.o.ag(a3),null)
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
else break}b=B.a.W(B.a.O(a3,q,d))
a=A.a3(b,null)
if(a==null)a=A.aH(b)
if(a!=null)return A.cg(a)}else if(e===34){d=q+1
for(a0=d,a1=!1;p=a0<s,p;){c=a3.charCodeAt(a0)
if(a1)a1=!1
else{a1=c===92
if(!a1)if(c===34)break}++a0}if(p)return new A.m(B.a.O(a3,d,a0))}else if(B.a.c4(a3,"true",q))return A.v(1)
else if(B.a.c4(a3,"false",q))return A.v(0)
else if(B.a.c4(a3,"null",q))return new A.d()
else if(e===123||e===91)break}break}else if(g&&a3.charCodeAt(q)===123){a2=r+1;++q
r=a2
break}else return new A.d()}++q}if(q>=s)break}return new A.L(B.o.ag(a3),null).ek(a4)},
rc(a){if(B.a.U(a,"$."))a=B.a.az(a,2)
else if(B.a.U(a,"$"))a=B.a.az(a,1)
if(a.length===0)return A.a([],t.s)
return A.a(a.split("."),t.s)},
r1(a){if(t.f.b(a)||t.j.b(a))return B.o.ag(B.o.bC(a))
return a},
iw(a,b,c){var s,r,q,p=null
if(b.length===0)return c
s=B.b.gH(b)
if(b.length===1)if(t.f.b(a)){r=A.Z(a,t.N,t.z)
r.k(0,s,c)
return r}else if(t.j.b(a)){q=A.a3(s,p)
if(q!=null&&q>=0){r=A.a6(a,!0,t.z)
while(r.length<=q)r.push(p)
r[q]=c
return r}}else{q=A.a3(s,p)
if(q!=null&&q>=0){r=[]
while(r.length<=q)r.push(p)
r[q]=c
return r}else return A.a7([s,c],t.N,t.z)}else if(t.f.b(a)){r=A.Z(a,t.N,t.z)
r.k(0,s,A.iw(r.h(0,s),B.b.ac(b,1),c))
return r}else if(t.j.b(a)){q=A.a3(s,p)
if(q!=null&&q>=0){r=A.a6(a,!0,t.z)
while(r.length<=q)r.push(p)
r[q]=A.iw(r[q],B.b.ac(b,1),c)
return r}}else{q=A.a3(s,p)
if(q!=null&&q>=0){r=[]
while(r.length<=q)r.push(p)
r[q]=A.iw(p,B.b.ac(b,1),c)
return r}else return A.a7([s,A.iw(p,B.b.ac(b,1),c)],t.N,t.z)}return a},
pw(a,b){var s,r,q
if(b.length===0)return a
s=B.b.gH(b)
if(b.length===1){if(t.f.b(a)){r=A.Z(a,t.N,t.z)
r.T(0,s)
return r}else if(t.j.b(a)){q=A.a3(s,null)
if(q!=null&&q>=0&&q<J.O(a)){r=A.a6(a,!0,t.z)
B.b.aM(r,q)
return r}}}else if(t.f.b(a)){if(a.D(s)){r=A.Z(a,t.N,t.z)
r.k(0,s,A.pw(r.h(0,s),B.b.ac(b,1)))
return r}}else if(t.j.b(a)){q=A.a3(s,null)
if(q!=null&&q>=0&&q<J.O(a)){r=A.a6(a,!0,t.z)
r[q]=A.pw(r[q],B.b.ac(b,1))
return r}}return a},
pv(a){if(a instanceof A.d)return null
if(a instanceof A.p)return a.a
if(a instanceof A.j)return a.a
if(a instanceof A.m)return a.a
if(a instanceof A.L)return a.ga2()
if(a instanceof A.a5)return a.a
return a.ga2()},
r4(a,b,c){var s,r,q,p
if(b instanceof A.d)return new A.d()
r=A.rc(b.l(0))
s=null
if(a instanceof A.L)s=A.r1(a.ga2())
else if(a instanceof A.m)try{s=B.o.ag(a.a)}catch(q){s=a.a}else if(a instanceof A.d)s=null
else s=a.ga2()
p=A.pv(c)
return new A.L(A.iw(s,r,p),null)},
r3(a,b){var s,r,q
if(b instanceof A.d)return new A.d()
r=A.rc(b.l(0))
s=null
if(a instanceof A.L)s=A.r1(a.ga2())
else if(a instanceof A.m)try{s=B.o.ag(a.a)}catch(q){s=a.a}else if(a instanceof A.d)s=null
else s=a.ga2()
return new A.L(A.pw(s,r),null)},
w1(a){var s=A.z(a).i("h<1,@>"),r=A.r(new A.h(a,A.wp(),s),s.i("u.E"))
return new A.L(r,null)},
w2(a){var s,r
if(B.c.a7(a.length,2)!==0)throw A.c(A.q("JSON_OBJECT requires an even number of arguments"))
s=A.o(t.N,t.z)
for(r=0;r<a.length;r+=2)s.k(0,a[r].l(0),A.pv(a[r+1]))
return new A.L(s,null)},
qm(a){var s,r,q,p,o,n,m=a.toLowerCase()
for(s=$.cU.length-1,r="."+a;s>=0;--s){q=$.cU[s]
if(q.D(a))return q.h(0,a)
for(p=q.gZ(),p=p.gI(p);p.p();){o=p.gF()
if(o.toLowerCase()===m)return q.h(0,o)}for(p=q.gbY(),p=p.gI(p);p.p();){o=p.gF()
n=o.a
if(B.a.B(n,r)||n===a)return o.b}}return null},
k:function k(){},
j0:function j0(){},
j1:function j1(){},
d:function d(){},
p:function p(a){this.a=a},
j:function j(a){this.a=a},
m:function m(a){this.a=a},
a5:function a5(a){this.a=a},
L:function L(a,b){this.a=a
this.b=null
this.c=b},
aN:function aN(a,b){this.a=a
this.b=b},
aO:function aO(a){this.a=a},
j_:function j_(){},
aG:function aG(a){this.a=a},
bn:function bn(a){this.a=a},
bm:function bm(a){this.a=a},
b_:function b_(a){this.a=a},
iZ:function iZ(){},
a8:function a8(a){this.a=a},
p2(a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p){var s
if(h==null)s=g!=null?A.a([g],t.R):B.b9
else s=h
return new A.aS(l,n,c,b,m,s,o,d,e,k,i,j,p,f,a)},
R(a){var s,r,q,p,o,n=", ",m=a.a
if(m!=null)return m
if(a instanceof A.aQ)s=a.b
else if(a instanceof A.ag)s=J.x(a.b)
else if(a instanceof A.I)s=B.b.S(a.b,".")
else if(a instanceof A.a0)s=A.R(a.c)+" "+a.b+" "+A.R(a.d)
else if(a instanceof A.af){m=a.c
s=a.b.toLowerCase()+"("+new A.h(m,A.iu(),A.z(m).i("h<1,e>")).S(0,n)+")"}else if(a instanceof A.bM){m=a.d
r=m.length===0?"":"PARTITION BY "+new A.h(m,A.iu(),A.z(m).i("h<1,e>")).S(0,n)
m=a.e
if(m!=null){q=A.R(m.a)
m=m.b?"ASC":"DESC"
p="ORDER BY "+q+" "+m}else p=""
m=A.a([],t.s)
if(r.length!==0)m.push(r)
if(p.length!==0)m.push(p)
s=a.b.toUpperCase()+"() OVER ("+B.b.S(m," ")+")"}else if(a instanceof A.cv)s="["+B.b.S(a.b,n)+"]"
else if(a instanceof A.b9){o=a.d?"->>":"->"
s=A.R(a.b)+o+"'"+a.c+"'"}else if(a instanceof A.cs)s="(SELECT ...)"
else if(a instanceof A.dR){m=a.b
s="ROLLUP("+new A.h(m,A.iu(),A.z(m).i("h<1,e>")).S(0,n)+")"}else if(a instanceof A.dn){m=a.b
s="CUBE("+new A.h(m,A.iu(),A.z(m).i("h<1,e>")).S(0,n)+")"}else if(a instanceof A.cJ){m=a.b
s="GROUPING SETS("+new A.h(m,new A.og(),A.z(m).i("h<1,e>")).S(0,n)+")"}else s=a instanceof A.ce?"CAST("+A.R(a.b)+" AS "+a.c.b.toUpperCase()+")":"Instance of '"+A.eV(a)+"'"
return a.a=s},
av:function av(a,b){this.a=a
this.b=b},
y:function y(){},
M:function M(){},
ag:function ag(a){this.b=a
this.a=null},
aQ:function aQ(a,b){this.b=a
this.c=b
this.a=null},
I:function I(a){this.b=a
this.a=null},
a0:function a0(a,b,c){var _=this
_.b=a
_.c=b
_.d=c
_.a=null},
af:function af(a,b){this.b=a
this.c=b
this.a=null},
bM:function bM(a,b,c,d){var _=this
_.b=a
_.c=b
_.d=c
_.e=d
_.a=null},
cv:function cv(a){this.b=a
this.a=null},
b9:function b9(a,b,c){var _=this
_.b=a
_.c=b
_.d=c
_.a=null},
cs:function cs(a){this.b=a
this.a=null},
dR:function dR(a){this.b=a
this.a=null},
dn:function dn(a){this.b=a
this.a=null},
cJ:function cJ(a){this.b=a
this.a=null},
e7:function e7(a){this.b=a},
aZ:function aZ(a,b,c,d,e,f,g,h,i,j){var _=this
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
bp:function bp(a,b,c,d,e,f,g){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g},
dH:function dH(a,b){this.a=a
this.b=b},
G:function G(){},
hY:function hY(){},
hD:function hD(a){this.b=a},
hE:function hE(a,b,c){this.a=a
this.b=b
this.c=c},
dk:function dk(a,b,c,d,e){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e},
dg:function dg(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
eI:function eI(a,b){this.b=a
this.c=b
this.a=null},
db:function db(a,b){this.a=a
this.b=b},
bR:function bR(a,b,c,d,e,f,g,h){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g
_.w=h},
cL:function cL(a,b,c,d,e,f,g,h){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g
_.w=h},
dp:function dp(a,b){this.a=a
this.b=b},
fo:function fo(a,b,c,d){var _=this
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
dm:function dm(a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r){var _=this
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
cW:function cW(a,b){this.a=a
this.b=b},
dy:function dy(a){this.a=a},
dr:function dr(a){this.a=a},
hZ:function hZ(a,b,c){this.a=a
this.b=b
this.c=c},
h7:function h7(a,b){this.a=a
this.b=b},
ch:function ch(a,b){this.a=a
this.b=b},
dL:function dL(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
e9:function e9(a,b){this.a=a
this.b=b},
ha:function ha(a,b){this.a=a
this.b=b},
ez:function ez(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
fr:function fr(a,b){this.a=a
this.b=b},
ek:function ek(a){this.a=a},
ea:function ea(){},
ee:function ee(){},
f3:function f3(){},
ey:function ey(a,b,c){this.a=a
this.b=b
this.c=c},
f1:function f1(a,b,c){this.a=a
this.b=b
this.c=c},
f8:function f8(a){this.a=a},
f7:function f7(a,b){this.a=a
this.b=b},
ei:function ei(a){this.a=a},
fp:function fp(a){this.a=a},
dj:function dj(a,b,c,d,e){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e},
dh:function dh(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
du:function du(){},
es:function es(a){this.a=a},
dc:function dc(a){this.a=a},
fc:function fc(){},
fa:function fa(a){this.a=a},
di:function di(a,b,c){this.a=a
this.b=b
this.c=c},
hC:function hC(a){this.a=a},
cG:function cG(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
cF:function cF(a,b,c,d,e){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e},
ec:function ec(a,b){this.a=a
this.b=b},
f_:function f_(a){this.a=a},
dQ:function dQ(a){this.a=a},
f6:function f6(a){this.a=a},
f2:function f2(a){this.a=a},
eZ:function eZ(a){this.a=a},
eQ:function eQ(a){this.a=a},
et:function et(a,b){this.a=a
this.b=b},
ed:function ed(a){this.a=a},
dl:function dl(a,b,c,d,e,f,g,h){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g
_.w=h},
dX:function dX(a,b){this.a=a
this.b=b},
dd:function dd(a,b){this.b=a
this.c=b
this.a=null},
ce:function ce(a,b){this.b=a
this.c=b
this.a=null},
em:function em(a,b){this.a=a
this.b=b},
cH:function cH(a){this.a=a},
f9:function f9(a){this.a=a},
fb:function fb(){},
eS:function eS(a){this.a=a},
fl:function fl(a){this.a=a},
el:function el(a){this.a=a},
ew:function ew(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
cf:function cf(a,b,c){this.a=a
this.b=b
this.c=c},
ej:function ej(a){this.a=a},
eo:function eo(a,b){this.a=a
this.b=b},
og:function og(){},
c1:function c1(a){var _=this
_.a=a
_.b=0
_.d=_.c=1},
c3:function c3(a){this.a=a
this.c=this.b=0},
mh:function mh(){},
mi:function mi(){},
mj:function mj(){},
f:function f(a,b){this.a=a
this.b=b},
N:function N(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
iA:function iA(a){this.a=a},
h1(a,b,c){var s=new A.h0(a,b,c),r=c*8
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
aY:function aY(a,b){this.a=a
this.b=b},
h0:function h0(a,b,c){var _=this
_.a=a
_.b=b
_.c=c
_.e=_.d=0
_.f=!1
_.x=_.w=_.r=null
_.ax=_.at=_.as=_.Q=_.z=_.y=$},
h2:function h2(a,b){this.a=a
this.b=b},
qf(a,b){var s=new A.eW(a,b),r=new A.c3(new A.c1(b).bt()).dI()
if(r instanceof A.cG){s.c=r.b
s.d=r.c}else A.ap(A.q("Invalid procedure SQL stored in catalog"))
return s},
tE(a){return A.qf(a.h(0,"name"),a.h(0,"sql"))},
pU(a,b){var s=new A.ex(a,b),r=new A.c3(new A.c1(b).bt()).dI()
if(r instanceof A.cF){s.c=r.b
s.d=r.c
s.e=r.d}else A.ap(A.q("Invalid function SQL stored in catalog"))
return s},
tb(a){return A.pU(a.h(0,"name"),a.h(0,"sql"))},
qq(a,b,c,d,e,f){var s=new A.cV(c,f,a,e,b,d),r=new A.c3(new A.c1(d).bt()).dI()
if(r instanceof A.dl){s.r=r.f
s.w=r.r}else A.ap(A.q("Invalid trigger SQL stored in catalog"))
return s},
tR(a){var s=a.h(0,"name"),r=a.h(0,"timing"),q=a.h(0,"event"),p=a.h(0,"tableName"),o=a.h(0,"forEachRow")
if(o==null)o=!1
return A.qq(q,o,s,a.h(0,"sql"),p,r)},
bL(a,b,c,d,e,f,g,h,i,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1){var s=null,r=f==null?A.a9(d.length,!1,!1,t.y):f,q=a0==null?A.a9(d.length,!1,!1,t.y):a0,p=h==null?A.a9(d.length,s,!1,t.T):h,o=g==null?A.a9(d.length,s,!1,t.T):g,n=e==null?A.a9(d.length,!1,!1,t.y):e,m=b==null?A.a9(d.length,s,!1,t.O):b,l=a==null?A.a9(d.length,s,!1,t.O):a,k=b1==null?A.a([],t.dG):b1,j=c==null?A.a9(d.length,s,!1,t.T):c
r=new A.c6(a5,d,i,a3,r,q,p,o,n,m,l,k,j,a4,a2,a1,a6,a9,a8,b0,a7==null?A.a([],t.s):a7)
r.fV(a,b,c,d,e,f,g,h,i,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1)
return r},
tQ(b2){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b="columnDefaultValues",a=null,a0="columnCheckExpressions",a1="columnPrimaryKey",a2="columnUnique",a3="columnReferencesTable",a4="columnReferencesColumn",a5="columnOnDeleteCascade",a6="policies",a7="foreignOptions",a8="partitionChildren",a9=t.N,b0=A.a6(b2.h(0,"columnNames"),!0,a9),b1=t.O
if(b2.D(b)){s=J.bG(t.j.a(b2.h(0,b)),new A.mP(),b1)
r=A.r(s,s.$ti.i("u.E"))}else r=A.a9(b0.length,a,!1,b1)
if(b2.D(a0)){b1=J.bG(t.j.a(b2.h(0,a0)),new A.mQ(),b1)
q=A.r(b1,b1.$ti.i("u.E"))}else q=A.a9(b0.length,a,!1,b1)
b1=b2.h(0,"name")
s=t.j
p=J.bG(s.a(b2.h(0,"columnTypes")),new A.mR(),t.q)
p=A.r(p,p.$ti.i("u.E"))
o=b2.h(0,"isColumnar")
if(o==null)o=!1
n=b2.D(a1)?A.a6(b2.h(0,a1),!0,t.y):a
m=b2.D(a2)?A.a6(b2.h(0,a2),!0,t.y):a
l=b2.D(a3)?A.a6(b2.h(0,a3),!0,t.T):a
k=b2.D(a4)?A.a6(b2.h(0,a4),!0,t.T):a
j=b2.D(a5)?A.a6(b2.h(0,a5),!0,t.y):a
if(b2.D(a6)){s=J.bG(s.a(b2.h(0,a6)),new A.mS(),t.dV)
s=A.r(s,s.$ti.i("u.E"))}else s=a
i=b2.h(0,"isForeign")
if(i==null)i=!1
h=b2.h(0,"foreignServer")
g=b2.h(0,a7)!=null?A.Z(b2.h(0,a7),a9,a9):a
f=b2.h(0,"partitionByColumn")
e=b2.h(0,"partitionOfParent")
d=b2.h(0,"partitionFromValue")
c=b2.h(0,"partitionToValue")
return A.bL(q,r,a,b0,j,n,k,l,p,m,g,h,o,i,b1,f,b2.h(0,a8)!=null?A.a6(b2.h(0,a8),!0,a9):a,d,e,c,s)},
tJ(a){return new A.dP(a.h(0,"name"),a.h(0,"fromTable"),a.h(0,"toTable"),a.h(0,"fromKey"),a.h(0,"toKey"))},
th(a){return new A.b8(a.h(0,"name"),a.h(0,"tableName"),a.h(0,"columnName"),a.h(0,"usingMethod"))},
qn(a){var s=t.N
return new A.bt(a,A.o(s,t.dP),A.o(s,t.cv))},
qo(a){var s="columnStats",r="histograms",q=a.h(0,"rowCount"),p=A.qn(q==null?0:q)
if(a.D(s))t.a.a(a.h(0,s)).a1(0,new A.n0(p))
if(a.D(r))t.a.a(a.h(0,r)).a1(0,new A.n1(p))
return p},
eW:function eW(a,b){var _=this
_.a=a
_.b=b
_.d=_.c=$},
ex:function ex(a,b){var _=this
_.a=a
_.b=b
_.e=_.d=_.c=$},
cV:function cV(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.w=_.r=$},
br:function br(a,b){this.a=a
this.b=b},
c6:function c6(a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,a0,a1){var _=this
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
mT:function mT(){},
mU:function mU(){},
mV:function mV(){},
mW:function mW(){},
mX:function mX(){},
mY:function mY(){},
mZ:function mZ(){},
n_:function n_(){},
mP:function mP(){},
mQ:function mQ(){},
mR:function mR(){},
mS:function mS(){},
dP:function dP(a,b,c,d,e){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e},
b8:function b8(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
iB:function iB(a,b,c,d,e,f,g,h,i,j){var _=this
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
iG:function iG(a,b,c){this.a=a
this.b=b
this.c=c},
iH:function iH(){},
iI:function iI(){},
iC:function iC(){},
iJ:function iJ(a){this.a=a},
iK:function iK(a){this.a=a},
iL:function iL(a){this.a=a},
iM:function iM(a){this.a=a},
iN:function iN(a){this.a=a},
iO:function iO(a){this.a=a},
iP:function iP(a){this.a=a},
iF:function iF(){},
iE:function iE(a,b){this.a=a
this.b=b},
iD:function iD(a){this.a=a},
bq:function bq(a,b,c){this.a=a
this.b=b
this.c=c},
df:function df(a){this.a=a},
bt:function bt(a,b,c){this.a=a
this.b=b
this.c=c},
n2:function n2(){},
n3:function n3(){},
n0:function n0(a){this.a=a},
n1:function n1(a){this.a=a},
ty(a){var s,r,q,p="al",o="ic"
a=B.a.W(a.toLowerCase())
s=a.length
if(s<3)return a
if(B.a.B(a,"sses"))a=B.a.O(a,0,s-2)
else if(B.a.B(a,"ies"))a=B.a.O(a,0,s-2)+"i"
else if(!B.a.B(a,"ss"))if(B.a.B(a,"s")&&!B.a.B(a,"us")&&!B.a.B(a,"is")&&!B.a.B(a,"as"))a=B.a.O(a,0,s-1)
if(B.a.B(a,"eed")){r=B.a.O(a,0,a.length-3)
if(A.dM(r)>0)a=r+"ee"}else if(B.a.B(a,"ing")){r=B.a.O(a,0,a.length-3)
if(A.oZ(r))a=A.q9(r)}else if(B.a.B(a,"ed")){r=B.a.O(a,0,a.length-2)
if(A.oZ(r))a=A.q9(r)}if(B.a.B(a,"y")&&A.oZ(B.a.O(a,0,a.length-1)))a=B.a.O(a,0,a.length-1)+"i"
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
if(B.a.B(a,p)||B.a.B(a,"ance")||B.a.B(a,"ence")||B.a.B(a,"er")||B.a.B(a,o)||B.a.B(a,"able")||B.a.B(a,"ible")||B.a.B(a,"ant")||B.a.B(a,"ement")||B.a.B(a,"ment")||B.a.B(a,"ent")){r=B.a.O(a,0,a.length-A.tx(a,A.a(["al","ance","ence","er","ic","able","ible","ant","ement","ment","ent"],t.s)).length)
if(A.dM(r)>1)a=r}else if(B.a.B(a,"ion")){r=B.a.O(a,0,a.length-3)
if((B.a.B(r,"s")||B.a.B(r,"t"))&&A.dM(r)>1)a=r}if(B.a.B(a,"e")){r=B.a.O(a,0,a.length-1)
q=A.dM(r)
if(q<=1)s=q===1&&!A.qa(r)
else s=!0
if(s)a=r}return B.a.B(a,"l")&&A.qb(a)&&A.dM(a)>1?B.a.O(a,0,a.length-1):a},
dM(a){var s,r,q,p,o
for(s=a.length,r=0,q=!1,p=0;p<s;++p){o=A.eR(a,p)
if(o&&!q)q=!0
else if(!o&&q){++r
q=!1}}return r},
oZ(a){var s,r
for(s=a.length,r=0;r<s;++r)if(A.eR(a,r))return!0
return!1},
eR(a,b){var s=a[b]
if(B.a.E("aeiou",s))return!0
if(s==="y"&&b>0&&!A.eR(a,b-1))return!0
return!1},
q9(a){if(B.a.B(a,"at")||B.a.B(a,"bl")||B.a.B(a,"iz"))return a+"e"
if(A.qb(a)&&!B.a.B(a,"l")&&!B.a.B(a,"s")&&!B.a.B(a,"z"))return B.a.O(a,0,a.length-1)
if(A.dM(a)===1&&A.qa(a))return a+"e"
return a},
qb(a){var s,r=a.length
if(r<2)return!1
s=a[r-1]
return s===a[r-2]&&!B.a.E("aeiou",s)},
qa(a){var s,r,q=a.length
if(q<3)return!1
s=q-1
r=a[s]
return!A.eR(a,s)&&A.eR(a,q-2)&&!A.eR(a,q-3)&&r!=="w"&&r!=="x"&&r!=="y"},
aM(a,b,c){var s=B.a.O(a,0,a.length-b.length)
if(A.dM(s)>0)return s+c
return a},
tx(a,b){var s,r
for(s=0;s<11;++s){r=b[s]
if(B.a.B(a,r))return r}return""},
rf(a){var s,r,q,p=A.aI("[^\\w\\s]",!0),o=B.a.cR(A.S(a,p," ").toLowerCase(),A.aI("\\s+",!0)),n=A.a([],t.s)
for(p=o.length,s=0;s<o.length;o.length===p||(0,A.n)(o),++s){r=o[s]
if(r.length===0)continue
if(B.cQ.E(0,r))continue
q=A.ty(r)
if(q.length!==0)n.push(q)}return n},
bH:function bH(a,b){this.a=a
this.b=b},
hh:function hh(a,b){this.a=a
this.b=b},
j9:function j9(){},
ja:function ja(a,b){this.a=a
this.b=b},
jc:function jc(a){this.a=a},
jb:function jb(a){this.a=a},
oL(a,b,c){var s=A.a([],t.ae),r=new A.id()
r.dT(42)
return new A.jx(b,1/Math.log(16),!1,c,s,r)},
cK:function cK(a,b,c,d,e){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e},
jx:function jx(a,b,c,d,e,f){var _=this
_.a=a
_.f=b
_.r=c
_.w=d
_.x=e
_.y=null
_.z=-1
_.Q=f},
jy:function jy(){},
jz:function jz(a){this.a=a},
jA:function jA(a){this.a=a},
jB:function jB(){},
jC:function jC(a,b){this.a=a
this.b=b},
jD:function jD(){},
jE:function jE(){},
jF:function jF(a,b){this.a=a
this.b=b},
jG:function jG(){},
jH:function jH(a){this.a=a},
ay:function ay(a,b){this.a=a
this.b=b},
q_(a,b,c){return new A.ho(b,!1,c,A.a([],t.G),A.o(t.S,t.gB),A.a([],t.D))},
bo:function bo(a,b,c){this.a=a
this.b=b
this.c=c},
ho:function ho(a,b,c,d,e,f){var _=this
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
tI(a0,a1,a2,a3,a4,a5){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a=a0===$.ow()?$.rE():A.aq(a0,0,null)
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
r+=5}else B.r.c2(a,l,n)}}else if(o instanceof A.j){q&2&&A.i(a0)
a0[r]=2
a.setFloat64(r+1,o.a,!1)
r+=9}else if(o instanceof A.m){q&2&&A.i(a0)
a0[r]=3
k=o.a
j=k.length
if(j<=1024){m=r+1
B.j.a8(a0,m,m+j,new A.de(k))
r+=1+j}else{i=B.x.aC(k)
h=a5.dN(i)
a0[r]=6
a.setUint32(r+1,h,!1)
a.setUint32(r+5,i.length,!1)
r+=9}}else if(o instanceof A.a5){q&2&&A.i(a0)
a0[r]=4
m=o.a
l=J.X(m)
g=l.gt(m)
for(f=r+1,e=0;e<g;++e)a.setFloat64(f+e*8,l.h(m,e),!1)
r+=1+g*8}else if(o instanceof A.L){q&2&&A.i(a0)
a0[r]=5
m=o.a
d=B.o.bC(m==null?o.a=B.o.ag(o.gaP()):m)
j=d.length
e=0
for(;;){if(!(e<j)){c=!0
break}if(d.charCodeAt(e)>127){c=!1
break}++e}if(c){m=r+1
if(j>1024){i=new Uint8Array(A.bx(new A.de(d)))
h=a5.dN(i)
a0[r]=7
a.setUint32(m,h,!1)
a.setUint32(r+5,i.length,!1)
r+=9}else{B.j.a8(a0,m,m+j,new A.de(d))
r+=1+j}}else{i=B.x.aC(d)
m=i.length
l=r+1
if(m>1024){h=a5.dN(i)
a0[r]=7
a.setUint32(l,h,!1)
a.setUint32(r+5,m,!1)
r+=9}else{B.j.a8(a0,l,l+m,i)
r+=1+m}}}else if(o instanceof A.aG){q&2&&A.i(a0)
a0[r]=8
m=o.a?1:0
a0[r+1]=m
r+=2}else if(o instanceof A.bn){q&2&&A.i(a0)
a0[r]=9
i=B.x.aC(o.a)
m=r+1
l=i.length
B.j.a8(a0,m,m+l,i)
r+=1+l}else if(o instanceof A.bm){q&2&&A.i(a0)
a0[r]=10
B.r.c2(a,r+1,o.a.a)}else if(o instanceof A.b_){q&2&&A.i(a0)
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
p0(a){var s,r,q=a.length,p=2+q*2,o=A.z(a).i("h<1,ba>"),n=A.r(new A.h(a,new A.mH(),o),o.i("u.E")),m=B.b.iK(n,0,new A.mI()),l=new Uint8Array(p+m),k=A.aq(l,0,null)
k.$flags&2&&A.i(k,10)
k.setUint16(0,q,!1)
for(s=p,r=0;r<q;++r){k.$flags&2&&A.i(k,10)
k.setUint16(2+r*2,s,!1)
B.j.aj(l,s,n[r])
s+=n[r].length}return l},
a4(a,b,c){var s,r,q,p,o,n,m,l=A.aq(a,0,null),k=l.getUint16(0,!1),j=A.a([],t.K)
for(s=a.length,r=c!=null,q=0;q<k;){p=l.getUint16(2+q*2,!1);++q
o=(q<k?l.getUint16(2+q*2,!1):s)-p
if(o>0){n=l.getUint8(p)
if(n===6)if(r){m=c.cE(l.getUint32(p+1,!1),l.getUint32(p+5,!1))
j.push(new A.m(new A.d2(!1).bK(m,0,null,!0)))}else j.push(new A.d())
else if(n===7)if(r)j.push(new A.L(null,c.cE(l.getUint32(p+1,!1),l.getUint32(p+5,!1))))
else j.push(new A.d())
else j.push(A.bV(l,p,o))}else j.push(new A.d())}if(b!=null&&j.length<b)while(j.length<b)j.push(new A.d())
return j},
qh(a,b,c,d){var s,r,q,p,o=a.getUint16(b,!1)
if(d>=o)return new A.d()
s=b+2
r=a.getUint16(s+d*2,!1)
q=d+1
p=q<o?a.getUint16(s+q*2,!1):c
return A.bV(a,b+r,p-r)},
fe(a){var s,r=a.c
r===$&&A.b()
r.$flags&2&&A.i(r,9)
r.setUint8(0,1)
r.setUint16(1,0,!1)
s=a.b.length
r.setUint16(3,s,!1)
a.w=0
a.x=s
a.d=!0},
fd(a){var s=a.w
if(s==null){s=a.c
s===$&&A.b()
s=a.w=s.getUint16(1,!1)}return s},
qk(a){var s=a.x
if(s==null){s=a.c
s===$&&A.b()
s=a.x=s.getUint16(3,!1)}return s},
p3(a,b){var s,r,q,p,o,n,m=a.c
m===$&&A.b()
s=A.fd(a)
r=A.qk(a)
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
cT(a,b,c){var s,r,q,p,o,n=a.c
n===$&&A.b()
s=A.fd(a)
r=A.qk(a)
q=5+s*4
if(r-q<c+4)return!1
p=r-c
B.j.aG(a.b,p,p+c,b,0)
n.$flags&2&&A.i(n,10)
n.setUint16(q,p,!1)
n.setUint16(q+2,c,!1)
o=s+1
a.w=o
a.x=p
n.setUint16(1,o,!1)
n.setUint16(3,p,!1)
return a.d=!0},
ab(a,b){var s,r,q,p=a.c
p===$&&A.b()
if(b>=A.fd(a))return null
s=5+b*4
r=p.getUint16(s,!1)
q=p.getUint16(s+2,!1)
if(q===0||r>=a.b.length)return null
p=a.b
return J.bk(B.j.gai(p),p.byteOffset+r,q)},
aR(a,b,c){var s=new A.cp(a,c,b)
s.d=new A.fk(a,b,c)
return s},
mH:function mH(){},
mI:function mI(){},
cp:function cp(a,b,c){var _=this
_.a=a
_.b=b
_.c=c
_.d=$
_.r=_.f=null
_.w=-1},
hM:function hM(a,b,c,d,e,f,g,h,i,j){var _=this
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
bS:function bS(a,b,c){this.a=a
this.b=b
this.c=c},
fk:function fk(a,b,c){this.a=a
this.b=b
this.c=c},
n8(){var s=0,r=A.b5(t.cE),q,p,o,n,m,l,k,j,i,h,g,f
var $async$n8=A.b6(function(a,b){if(a===1)return A.b2(b,r)
for(;;)switch(s){case 0:f=":memory:"
try{o=A.t3()
o=o.a
if(o==="")A.ap(A.bl("Directory.createTemp called with an empty path. To use the system temp directory, use Directory.systemTemp",null))
if(!B.a.B(o,"/"))o=$.fW()&&B.a.B(o,"\\")
else o=!0
if(!o)A.D($.ot())
A.u_(A.bN(),void 1)
p=null}catch(e){f=":memory:"}m=A.oD(f,null)
s=3
return A.as(m.bq(),$async$n8)
case 3:o=new A.hS(m)
l=t.N
k=t.r
j=t.y
i=t._
h=t.de
l=new A.jO(m,A.o(l,k),A.a([],t.s),A.a([],t.f0),A.o(t.k,t.W),A.o(l,t.gZ),A.o(l,t.dU),A.o(l,j),A.o(i,t.S),A.o(i,l),A.o(h,t.eT),A.o(h,t.fs),A.o(h,t.eg),A.o(l,j),A.o(l,k),A.o(l,t.g6),A.o(l,t.aI))
k=m.c
k===$&&A.b()
g=new A.cS()
k.Q.push(g)
l.cy=g
o.b=l
q=o
s=1
break
case 1:return A.b3(q,r)}})
return A.b4($async$n8,r)},
hS:function hS(a){this.a=a
this.b=$},
hb:function hb(a,b,c){this.a=a
this.b=b
this.c=c},
om(){var s=0,r=A.b5(t.H),q,p,o
var $async$om=A.b6(function(a,b){if(a===1)return A.b2(b,r)
for(;;)switch(s){case 0:o=$.pd
s=2
return A.as(A.n8(),$async$om)
case 2:o.b=b
q=new A.on()
if(typeof q=="function")A.ap(A.bl("Attempting to rewrap a JS function.",null))
p=function(c,d){return function(e){return c(d,e,arguments.length)}}(A.uR,q)
p[$.os()]=q
v.G.executeUltSQL=p
A.cd("\u26a1 Real UltSQL 100% Pure Dart Engine Initialized in Browser!")
return A.b3(null,r)}})
return A.b4($async$om,r)},
o8(a){return A.vv(a)},
vv(a1){var s=0,r=A.b5(t.N),q,p=2,o=[],n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0
var $async$o8=A.b6(function(a2,a3){if(a2===1){o.push(a3)
s=p}for(;;)switch(s){case 0:a=new A.bK()
$.cC()
a.b7()
n=a
p=4
g=$.pd.b
if(g===$.pd)A.ap(A.q4(""))
s=7
return A.as(g.cD(a1),$async$o8)
case 7:m=a3
g=n
if(g.b==null)g.b=$.bs.$0()
g=B.h.fB(n.gbB()/1000,2)
f=m.a
e=m.b
d=A.z(e).i("h<1,t<e>>")
e=A.r(new A.h(e,new A.oa(),d),d.i("u.E"))
l=A.a7(["status","success","elapsedMs",g,"columns",f,"rows",e,"message",m.c],t.N,t.C)
c=B.o.dz(l,null)
q=c
s=1
break
p=2
s=6
break
case 4:p=3
a0=o.pop()
k=A.aU(a0)
g=n
if(g.b==null)g.b=$.bs.$0()
j=J.x(k)
i=A.vk(j)
h=A.a7(["status","error","elapsedMs",B.h.fB(n.gbB()/1000,2),"errorTitle",J.a_(i,"title"),"error",J.a_(i,"error"),"errorHint",J.a_(i,"hint"),"rawError",j],t.N,t.T)
q=B.o.dz(h,null)
s=1
break
s=6
break
case 3:s=2
break
case 6:case 1:return A.b3(q,r)
case 2:return A.b2(o.at(-1),r)}})
return A.b4($async$o8,r)},
vk(a){var s,r,q,p,o,n,m,l,k=B.a.W(a)
if(B.a.U(k,"Exception: "))k=B.a.W(B.a.az(k,11))
if(B.a.U(k,"Error: "))k=B.a.W(B.a.az(k,7))
s=A.aI("Table '([^']+)' does not exist",!1).bp(k)
if(s!=null){r=A.D(s.b[1])
q=t.N
return A.a7(["title","Table Not Found","error","Table '"+r+"' does not exist in the database catalog.","hint","Make sure you create the table first using 'CREATE TABLE "+r+" (...);' or check for spelling errors."],q,q)}p=A.aI("Table '([^']+)' already exists",!1).bp(k)
if(p!=null){r=A.D(p.b[1])
q=t.N
return A.a7(["title","Table Already Exists","error","A table named '"+r+"' already exists.","hint","Use 'DROP TABLE IF EXISTS "+r+";' before creating it, or choose a different table name."],q,q)}o=A.aI("Column '([^']+)' (?:does not exist|not found)",!1).bp(k)
if(o!=null){r=t.N
return A.a7(["title","Column Not Found","error","Column '"+A.D(o.b[1])+"' was not found in the referenced table schema.","hint","Check the column name spelling or run 'DESCRIBE <table>;' to see available columns."],r,r)}n=A.aI("Column count mismatch\\. Expected (\\d+) values, found (\\d+)",!1).bp(k)
if(n!=null){r=n.b
q=A.D(r[1])
m=t.N
return A.a7(["title","Column Count Mismatch","error","The INSERT statement supplied "+A.D(r[2])+" values, but the target table schema expects "+q+" columns.","hint","Specify explicit columns: 'INSERT INTO table (col1, col2) VALUES (...)' or supply all "+q+" values."],m,m)}if(B.a.E(k,"Expected ")||B.a.E(k,"Unexpected token")||B.a.E(k,"Syntax error")||B.a.E(k,"[Token")){l=B.a.E(k,"] ")?B.a.az(k,B.a.ad(k,"] ")+2):k
r=t.N
return A.a7(["title","SQL Syntax Error","error",l,"hint","Verify SQL keywords, commas between column names, quotes around text literals ('value'), and closing parentheses."],r,r)}if(B.a.E(k.toLowerCase(),"type mismatch")||B.a.E(k.toLowerCase(),"cannot cast")||B.a.E(k.toLowerCase(),"incompatible")){r=t.N
return A.a7(["title","Data Type Mismatch","error",k,"hint","Ensure your values match the column data types (e.g. single quotes for VARCHAR/TEXT, numbers for INT/DOUBLE)."],r,r)}if(B.a.E(k.toLowerCase(),"duplicate key")||B.a.E(k.toLowerCase(),"primary key constraint")||B.a.E(k.toLowerCase(),"unique constraint")){r=t.N
return A.a7(["title","Unique Constraint Violation","error",k,"hint","Primary key and UNIQUE columns must have distinct values. Consider using 'INSERT OR REPLACE' or distinct IDs."],r,r)}r=t.N
return A.a7(["title","Query Execution Error","error",k,"hint","Review the SQL statement structure and ensure referenced tables, columns, and data types are valid."],r,r)},
on:function on(){},
oa:function oa(){},
o9:function o9(){},
op(a){if(typeof dartPrint=="function"){dartPrint(a)
return}if(typeof console=="object"&&typeof console.log!="undefined"){console.log(a)
return}if(typeof print=="function"){print(a)
return}throw"Unable to print message: "+String(a)},
tH(){throw A.c(A.Y("new RawReceivePort"))},
pY(a,b){var s=null,r=new A.ft(new A.ad($.V,b.i("ad<0>")),b.i("ft<0>")),q=A.tH()},
uR(a,b,c){if(c>=1)return a.$1(b)
return a.$0()},
uS(a,b,c,d){if(d>=2)return a.$2(b,c)
if(d===1)return a.$1(b)
return a.$0()},
vX(a,b){var s,r
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
A.oR.prototype={}
J.hm.prototype={
aw(a,b){return a===b},
gY(a){return A.hJ(a)},
l(a){return"Instance of '"+A.eV(a)+"'"},
gak(a){return A.d6(A.ph(this))}}
J.eC.prototype={
l(a){return String(a)},
gY(a){return a?519018:218159},
gak(a){return A.d6(t.y)},
$iac:1,
$iQ:1}
J.eE.prototype={
aw(a,b){return null==b},
l(a){return"null"},
gY(a){return 0},
$iac:1,
$iaE:1}
J.ar.prototype={$ial:1}
J.cl.prototype={
gY(a){return 0},
l(a){return String(a)}}
J.hI.prototype={}
J.cu.prototype={}
J.be.prototype={
l(a){var s=a[$.rh()]
if(s==null)s=a[$.os()]
if(s==null)return this.fQ(a)
return"JavaScript function for "+J.x(s)}}
J.dB.prototype={
gY(a){return 0},
l(a){return String(a)}}
J.dC.prototype={
gY(a){return 0},
l(a){return String(a)}}
J.C.prototype={
R(a,b){a.$flags&1&&A.i(a,29)
a.push(b)},
aM(a,b){a.$flags&1&&A.i(a,"removeAt",1)
if(b<0||b>=a.length)throw A.c(A.mG(b,null))
return a.splice(b,1)[0]},
dC(a,b,c){a.$flags&1&&A.i(a,"insert",2)
if(b<0||b>a.length)throw A.c(A.mG(b,null))
a.splice(b,0,c)},
T(a,b){var s
a.$flags&1&&A.i(a,"remove",1)
for(s=0;s<a.length;++s)if(J.az(a[s],b)){a.splice(s,1)
return!0}return!1},
fj(a,b,c){return new A.bX(a,b,A.z(a).i("@<1>").au(c).i("bX<1,2>"))},
X(a,b){a.$flags&1&&A.i(a,"addAll",2)
this.h_(a,b)
return},
h_(a,b){var s,r=b.length
if(r===0)return
if(a===b)throw A.c(A.aA(a))
for(s=0;s<r;++s)a.push(b[s])},
v(a){a.$flags&1&&A.i(a,"clear","clear")
a.length=0},
bd(a,b,c){return new A.h(a,b,A.z(a).i("@<1>").au(c).i("h<1,2>"))},
S(a,b){var s,r=A.a9(a.length,"",!1,t.N)
for(s=0;s<a.length;++s)r[s]=A.D(a[s])
return r.join(b)},
iJ(a,b,c){var s,r,q=a.length
for(s=b,r=0;r<q;++r){s=c.$2(s,a[r])
if(a.length!==q)throw A.c(A.aA(a))}return s},
iK(a,b,c){return this.iJ(a,b,c,t.z)},
iI(a,b,c){var s,r,q,p=a.length
for(s=0;s<p;++s){r=a[s]
if(b.$1(r))return r
if(a.length!==p)throw A.c(A.aA(a))}q=c.$0()
return q},
an(a,b){return a[b]},
bj(a,b,c){if(b<0||b>a.length)throw A.c(A.ax(b,0,a.length,"start",null))
if(c==null)c=a.length
else if(c<b||c>a.length)throw A.c(A.ax(c,b,a.length,"end",null))
if(b===c)return A.a([],A.z(a))
return A.a(a.slice(b,c),A.z(a))},
ac(a,b){return this.bj(a,b,null)},
gH(a){if(a.length>0)return a[0]
throw A.c(A.bZ())},
gV(a){var s=a.length
if(s>0)return a[s-1]
throw A.c(A.bZ())},
aG(a,b,c,d,e){var s,r,q,p
a.$flags&2&&A.i(a,5)
A.c4(b,c,a.length)
s=c-b
if(s===0)return
A.eX(e,"skipCount")
r=d
q=J.X(r)
if(e+s>q.gt(r))throw A.c(A.pZ())
if(e<b)for(p=s-1;p>=0;--p)a[b+p]=q.h(r,e+p)
else for(p=0;p<s;++p)a[b+p]=q.h(r,e+p)},
a8(a,b,c,d){return this.aG(a,b,c,d,0)},
bD(a,b,c,d){var s
a.$flags&2&&A.i(a,"fillRange")
A.c4(b,c,a.length)
for(s=b;s<c;++s)a[s]=d},
b1(a,b){var s,r=a.length
for(s=0;s<r;++s){if(b.$1(a[s]))return!0
if(a.length!==r)throw A.c(A.aA(a))}return!1},
cq(a,b){var s,r=a.length
for(s=0;s<r;++s){if(!b.$1(a[s]))return!1
if(a.length!==r)throw A.c(A.aA(a))}return!0},
ar(a,b){var s,r,q,p,o
a.$flags&2&&A.i(a,"sort")
s=a.length
if(s<2)return
if(b==null)b=J.v5()
if(s===2){r=a[0]
q=a[1]
if(b.$2(r,q)>0){a[0]=q
a[1]=r}return}p=0
if(A.z(a).c.b(null))for(o=0;o<a.length;++o)if(a[o]===void 0){a[o]=null;++p}a.sort(A.fU(b,2))
if(p>0)this.ic(a,p)},
dR(a){return this.ar(a,null)},
ic(a,b){var s,r=a.length
for(;s=r-1,r>0;r=s)if(a[s]===null){a[s]=void 0;--b
if(b===0)break}},
fP(a,b){var s,r,q
a.$flags&2&&A.i(a,"shuffle")
s=a.length
while(s>1){r=b.cA(s);--s
q=a[s]
a[s]=a[r]
a[r]=q}},
ad(a,b){var s,r=a.length
if(0>=r)return-1
for(s=0;s<r;++s)if(J.az(a[s],b))return s
return-1},
E(a,b){var s
for(s=0;s<a.length;++s)if(J.az(a[s],b))return!0
return!1},
ga9(a){return a.length===0},
gaa(a){return a.length!==0},
l(a){return A.oO(a,"[","]")},
aQ(a,b){var s=A.a(a.slice(0),A.z(a))
return s},
aN(a){return this.aQ(a,!0)},
gI(a){return new J.bd(a,a.length,A.z(a).i("bd<1>"))},
gY(a){return A.hJ(a)},
gt(a){return a.length},
h(a,b){if(!(b>=0&&b<a.length))throw A.c(A.oc(a,b))
return a[b]},
k(a,b,c){a.$flags&2&&A.i(a)
if(!(b>=0&&b<a.length))throw A.c(A.oc(a,b))
a[b]=c},
cu(a,b){var s
if(0>=a.length)return-1
for(s=0;s<a.length;++s)if(b.$1(a[s]))return s
return-1},
$iaP:1,
$iH:1,
$it:1,
ct(a,b){return this.gH(a).$1(b)}}
J.hq.prototype={
jg(a){var s,r,q
if(!Array.isArray(a))return null
s=a.$flags|0
if((s&4)!==0)r="const, "
else if((s&2)!==0)r="unmodifiable, "
else r=(s&1)!==0?"fixed, ":""
q="Instance of '"+A.eV(a)+"'"
if(r==="")return q
return q+" ("+r+"length: "+a.length+")"}}
J.l2.prototype={}
J.bd.prototype={
gF(){var s=this.d
return s==null?this.$ti.c.a(s):s},
p(){var s,r=this,q=r.a,p=q.length
if(r.b!==p)throw A.c(A.n(q))
s=r.c
if(s>=p){r.d=null
return!1}r.d=q[s]
r.c=s+1
return!0},
$ia1:1}
J.cM.prototype={
A(a,b){var s
if(a<b)return-1
else if(a>b)return 1
else if(a===b){if(a===0){s=this.gcz(b)
if(this.gcz(a)===s)return 0
if(this.gcz(a))return-1
return 1}return 0}else if(isNaN(a)){if(isNaN(b))return 0
return 1}else return-1},
gcz(a){return a===0?1/a<0:a<0},
be(a){var s
if(a>=-2147483648&&a<=2147483647)return a|0
if(isFinite(a)){s=a<0?Math.ceil(a):Math.floor(a)
return s+0}throw A.c(A.Y(""+a+".toInt()"))},
iy(a){var s,r
if(a>=0){if(a<=2147483647){s=a|0
return a===s?s:s+1}}else if(a>=-2147483648)return a|0
r=Math.ceil(a)
if(isFinite(r))return r
throw A.c(A.Y(""+a+".ceil()"))},
dA(a){var s,r
if(a>=0){if(a<=2147483647)return a|0}else if(a>=-2147483648){s=a|0
return a===s?s:s-1}r=Math.floor(a)
if(isFinite(r))return r
throw A.c(A.Y(""+a+".floor()"))},
fv(a){if(a>0){if(a!==1/0)return Math.round(a)}else if(a>-1/0)return 0-Math.round(0-a)
throw A.c(A.Y(""+a+".round()"))},
dt(a,b,c){if(B.c.A(b,c)>0)throw A.c(A.vF(b))
if(this.A(a,b)<0)return b
if(this.A(a,c)>0)return c
return a},
fB(a,b){var s
if(b>20)throw A.c(A.ax(b,0,20,"fractionDigits",null))
s=a.toFixed(b)
if(a===0&&this.gcz(a))return"-"+s
return s},
fA(a,b){var s,r,q,p
if(b<2||b>36)throw A.c(A.ax(b,2,36,"radix",null))
s=a.toString(b)
if(s.charCodeAt(s.length-1)!==41)return s
r=/^([\da-z]+)(?:\.([\da-z]+))?\(e\+(\d+)\)$/.exec(s)
if(r==null)A.ap(A.Y("Unexpected toString result: "+s))
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
aY(a,b){if((a|0)===a)if(b>=1||b<-1)return a/b|0
return this.f_(a,b)},
a3(a,b){return(a|0)===a?a/b|0:this.f_(a,b)},
f_(a,b){var s=a/b
if(s>=-2147483648&&s<=2147483647)return s|0
if(s>0){if(s!==1/0)return Math.floor(s)}else if(s>-1/0)return Math.ceil(s)
throw A.c(A.Y("Result of truncating division is "+A.D(s)+": "+A.D(a)+" ~/ "+b))},
eZ(a,b){return b>31?0:a<<b>>>0},
bW(a,b){var s
if(a>0)s=this.ip(a,b)
else{s=b>31?31:b
s=a>>s>>>0}return s},
ip(a,b){return b>31?0:a>>>b},
cN(a,b){return a<b},
gak(a){return A.d6(t.di)},
$iW:1}
J.eD.prototype={
gak(a){return A.d6(t.S)},
$iac:1,
$il:1}
J.hr.prototype={
gak(a){return A.d6(t.i)},
$iac:1}
J.ck.prototype={
f5(a,b){return new A.ij(b,a,0)},
dH(a,b,c){var s,r,q=null
if(c<0||c>b.length)throw A.c(A.ax(c,0,b.length,q,q))
s=a.length
if(c+s>b.length)return q
for(r=0;r<s;++r)if(b.charCodeAt(c+r)!==a.charCodeAt(r))return q
return new A.dT(c,a)},
B(a,b){var s=b.length,r=a.length
if(s>r)return!1
return b===this.az(a,r-s)},
cR(a,b){var s
if(typeof b=="string")return A.a(a.split(b),t.s)
else{if(b instanceof A.dA){s=b.e
s=!(s==null?b.e=b.h8():s)}else s=!1
if(s)return A.a(a.split(b.b),t.s)
else return this.hb(a,b)}},
hb(a,b){var s,r,q,p,o,n,m=A.a([],t.s)
for(s=J.pA(b,a),s=s.gI(s),r=0,q=1;s.p();){p=s.gF()
o=p.gcS()
n=p.gcp()
q=n-o
if(q===0&&r===o)continue
m.push(this.O(a,r,o))
r=n}if(r<a.length||q>0)m.push(this.az(a,r))
return m},
c4(a,b,c){var s,r=a.length
if(c>r)throw A.c(A.ax(c,0,r,null,null))
if(typeof b=="string"){s=c+b.length
if(s>r)return!1
return b===a.substring(c,s)}return J.rQ(b,a,c)!=null},
U(a,b){return this.c4(a,b,0)},
O(a,b,c){return a.substring(b,A.c4(b,c,a.length))},
az(a,b){return this.O(a,b,null)},
W(a){var s,r,q,p=a.trim(),o=p.length
if(o===0)return p
if(p.charCodeAt(0)===133){s=J.to(p,1)
if(s===o)return""}else s=0
r=o-1
q=p.charCodeAt(r)===133?J.tp(p,r):o
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
a0(a,b,c){var s=b-a.length
if(s<=0)return a
return this.P(c,s)+a},
j2(a,b,c){var s=b-a.length
if(s<=0)return a
return a+this.P(c,s)},
fm(a,b,c){var s,r,q,p
if(c<0||c>a.length)throw A.c(A.ax(c,0,a.length,null,null))
if(typeof b=="string")return a.indexOf(b,c)
if(b instanceof A.dA){s=b.ef(a,c)
return s==null?-1:s.b.index}for(r=a.length,q=J.e3(b),p=c;p<=r;++p)if(q.dH(b,a,p)!=null)return p
return-1},
ad(a,b){return this.fm(a,b,0)},
iV(a,b){var s,r=a.length
for(s=r;s>=0;--s){if(s>r)A.ap(A.ax(s,0,r,null,null))
if(b.ee(a,s)!=null)return s}return-1},
E(a,b){return A.wk(a,b,0)},
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
gak(a){return A.d6(t.N)},
gt(a){return a.length},
h(a,b){if(!(b>=0&&b<a.length))throw A.c(A.oc(a,b))
return a[b]},
$iaP:1,
$iac:1,
$ie:1}
A.nm.prototype={
R(a,b){var s,r=this,q=b.length
if(q===0)return
s=r.a+q
if(r.b.length<s)r.er(s)
B.j.a8(r.b,r.a,s,b)
r.a=s},
iu(a){var s=this,r=s.b,q=s.a
if(r.length===q)s.er(q)
r=s.b
q=s.a
r.$flags&2&&A.i(r)
r[q]=a
s.a=q+1},
er(a){var s,r,q,p=a*2
if(p<1024)p=1024
else{s=p-1
s|=B.c.bW(s,1)
s|=s>>>2
s|=s>>>4
s|=s>>>8
p=((s|s>>>16)>>>0)+1}r=new Uint8Array(p)
q=this.b
B.j.a8(r,0,q.length,q)
this.b=r},
jc(){var s,r=this
if(r.a===0)return $.ou()
s=J.bk(B.j.gai(r.b),r.b.byteOffset,r.a)
r.a=0
r.b=$.ou()
return s},
gt(a){return this.a},
gaa(a){return this.a!==0}}
A.cO.prototype={
l(a){return"LateInitializationError: "+this.a}}
A.de.prototype={
gt(a){return this.a.length},
h(a,b){return this.a.charCodeAt(b)}}
A.mM.prototype={}
A.H.prototype={}
A.u.prototype={
gI(a){var s=this
return new A.cQ(s,s.gt(s),A.E(s).i("cQ<u.E>"))},
ga9(a){return this.gt(this)===0},
gH(a){if(this.gt(this)===0)throw A.c(A.bZ())
return this.an(0,0)},
S(a,b){var s,r,q,p=this,o=p.gt(p)
if(b.length!==0){if(o===0)return""
s=A.D(p.an(0,0))
if(o!==p.gt(p))throw A.c(A.aA(p))
for(r=s,q=1;q<o;++q){r=r+b+A.D(p.an(0,q))
if(o!==p.gt(p))throw A.c(A.aA(p))}return r.charCodeAt(0)==0?r:r}else{for(q=0,r="";q<o;++q){r+=A.D(p.an(0,q))
if(o!==p.gt(p))throw A.c(A.aA(p))}return r.charCodeAt(0)==0?r:r}},
dE(a){return this.S(0,"")},
bd(a,b,c){return new A.h(this,b,A.E(this).i("@<u.E>").au(c).i("h<1,2>"))},
aQ(a,b){var s=A.r(this,A.E(this).i("u.E"))
return s},
aN(a){return this.aQ(0,!0)},
je(a){var s,r=this,q=A.oU(A.E(r).i("u.E"))
for(s=0;s<r.gt(r);++s)q.R(0,r.an(0,s))
return q}}
A.fi.prototype={
ghd(){var s=J.O(this.a),r=this.c
if(r==null||r>s)return s
return r},
gir(){var s=J.O(this.a),r=this.b
if(r>s)return s
return r},
gt(a){var s,r=J.O(this.a),q=this.b
if(q>=r)return 0
s=this.c
if(s==null||s>=r)return r-q
return s-q},
an(a,b){var s=this,r=s.gir()+b
if(b<0||r>=s.ghd())throw A.c(A.oN(b,s.gt(0),s,"index"))
return J.pC(s.a,r)},
aQ(a,b){var s,r,q,p=this,o=p.b,n=p.a,m=J.X(n),l=m.gt(n),k=p.c
if(k!=null&&k<l)l=k
s=l-o
if(s<=0){n=p.$ti.c
return b?J.oP(0,n):J.q0(0,n)}r=A.a9(s,m.an(n,o),b,p.$ti.c)
for(q=1;q<s;++q){r[q]=m.an(n,o+q)
if(m.gt(n)<l)throw A.c(A.aA(p))}return r},
aN(a){return this.aQ(0,!0)}}
A.cQ.prototype={
gF(){var s=this.d
return s==null?this.$ti.c.a(s):s},
p(){var s,r=this,q=r.a,p=J.X(q),o=p.gt(q)
if(r.b!==o)throw A.c(A.aA(q))
s=r.c
if(s>=o){r.d=null
return!1}r.d=p.an(q,s);++r.c
return!0},
$ia1:1}
A.cR.prototype={
gI(a){return new A.eH(J.au(this.a),this.b,A.E(this).i("eH<1,2>"))},
gt(a){return J.O(this.a)},
ga9(a){return J.pD(this.a)},
gH(a){return this.b.$1(J.e6(this.a))}}
A.en.prototype={$iH:1}
A.eH.prototype={
p(){var s=this,r=s.b
if(r.p()){s.a=s.c.$1(r.gF())
return!0}s.a=null
return!1},
gF(){var s=this.a
return s==null?this.$ti.y[1].a(s):s},
$ia1:1}
A.h.prototype={
gt(a){return J.O(this.a)},
an(a,b){return this.b.$1(J.pC(this.a,b))}}
A.aJ.prototype={
gI(a){return new A.fq(J.au(this.a),this.b,this.$ti.i("fq<1>"))}}
A.fq.prototype={
p(){var s,r
for(s=this.a,r=this.b;s.p();)if(r.$1(s.gF()))return!0
return!1},
gF(){return this.a.gF()},
$ia1:1}
A.bX.prototype={
gI(a){return new A.er(J.au(this.a),this.b,B.co,this.$ti.i("er<1,2>"))}}
A.er.prototype={
gF(){var s=this.d
return s==null?this.$ti.y[1].a(s):s},
p(){var s,r,q=this,p=q.c
if(p==null)return!1
for(s=q.a,r=q.b;!p.p();){q.d=null
if(s.p()){q.c=null
p=J.au(r.$1(s.gF()))
q.c=p}else return!1}q.d=q.c.gF()
return!0},
$ia1:1}
A.ep.prototype={
p(){return!1},
gF(){throw A.c(A.bZ())},
$ia1:1}
A.ev.prototype={
st(a,b){throw A.c(A.Y("Cannot change the length of a fixed-length list"))},
R(a,b){throw A.c(A.Y("Cannot add to a fixed-length list"))},
T(a,b){throw A.c(A.Y("Cannot remove from a fixed-length list"))}}
A.hW.prototype={
k(a,b,c){throw A.c(A.Y("Cannot modify an unmodifiable list"))},
st(a,b){throw A.c(A.Y("Cannot change the length of an unmodifiable list"))},
R(a,b){throw A.c(A.Y("Cannot add to an unmodifiable list"))},
T(a,b){throw A.c(A.Y("Cannot remove from an unmodifiable list"))},
ar(a,b){throw A.c(A.Y("Cannot modify an unmodifiable list"))},
aG(a,b,c,d,e){throw A.c(A.Y("Cannot modify an unmodifiable list"))},
a8(a,b,c,d){return this.aG(0,b,c,d,0)}}
A.dW.prototype={}
A.f0.prototype={
gt(a){return J.O(this.a)},
an(a,b){var s=this.a,r=J.X(s)
return r.an(s,r.gt(s)-1-b)}}
A.hR.prototype={
gY(a){var s=this._hashCode
if(s!=null)return s
s=664597*B.a.gY(this.a)&536870911
this._hashCode=s
return s},
l(a){return'Symbol("'+this.a+'")'},
aw(a,b){if(b==null)return!1
return b instanceof A.hR&&this.a===b.a}}
A.ig.prototype={$r:"+condFn,thenFn(1,2)",$s:1}
A.ef.prototype={
ga9(a){return this.gt(this)===0},
gaa(a){return this.gt(this)!==0},
l(a){return A.oW(this)},
k(a,b,c){A.oC()},
J(a,b){A.oC()},
T(a,b){A.oC()},
gbY(){return new A.cx(this.iE(),A.E(this).i("cx<aj<1,2>>"))},
iE(){var s=this
return function(){var r=0,q=1,p=[],o,n,m
return function $async$gbY(a,b,c){if(b===1){p.push(c)
r=q}for(;;)switch(r){case 0:o=s.gZ(),o=o.gI(o),n=A.E(s).i("aj<1,2>")
case 2:if(!o.p()){r=3
break}m=o.gF()
r=4
return a.b=new A.aj(m,s.h(0,m),n),1
case 4:r=2
break
case 3:return 0
case 1:return a.c=p.at(-1),3}}}},
$iw:1}
A.eh.prototype={
gt(a){return this.b.length},
gex(){var s=this.$keys
if(s==null){s=Object.keys(this.a)
this.$keys=s}return s},
D(a){if(typeof a!="string")return!1
if("__proto__"===a)return!1
return this.a.hasOwnProperty(a)},
h(a,b){if(!this.D(b))return null
return this.b[this.a[b]]},
a1(a,b){var s,r,q=this.gex(),p=this.b
for(s=q.length,r=0;r<s;++r)b.$2(q[r],p[r])},
gZ(){return new A.cZ(this.gex(),this.$ti.i("cZ<1>"))},
gaO(){return new A.cZ(this.b,this.$ti.i("cZ<2>"))}}
A.cZ.prototype={
gt(a){return this.a.length},
ga9(a){return 0===this.a.length},
gaa(a){return 0!==this.a.length},
gI(a){var s=this.a
return new A.d_(s,s.length,this.$ti.i("d_<1>"))}}
A.d_.prototype={
gF(){var s=this.d
return s==null?this.$ti.c.a(s):s},
p(){var s=this,r=s.c
if(r>=s.b){s.d=null
return!1}s.d=s.a[r]
s.c=r+1
return!0},
$ia1:1}
A.eg.prototype={
R(a,b){A.t_()}}
A.bT.prototype={
gt(a){return this.b},
ga9(a){return this.b===0},
gaa(a){return this.b!==0},
gI(a){var s,r=this,q=r.$keys
if(q==null){q=Object.keys(r.a)
r.$keys=q}s=q
return new A.d_(s,s.length,r.$ti.i("d_<1>"))},
E(a,b){if(typeof b!="string")return!1
if("__proto__"===b)return!1
return this.a.hasOwnProperty(b)}}
A.mk.prototype={
$0(){return B.h.dA(1000*this.a.now())},
$S:13}
A.f5.prototype={}
A.n6.prototype={
aW(a){var s,r,q=this,p=new RegExp(q.a).exec(a)
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
A.eP.prototype={
l(a){return"Null check operator used on a null value"}}
A.hs.prototype={
l(a){var s,r=this,q="NoSuchMethodError: method not found: '",p=r.b
if(p==null)return"NoSuchMethodError: "+r.a
s=r.c
if(s==null)return q+p+"' ("+r.a+")"
return q+p+"' on '"+s+"' ("+r.a+")"}}
A.hV.prototype={
l(a){var s=this.a
return s.length===0?"Error":"Error: "+s}}
A.lY.prototype={
l(a){return"Throw of null ('"+(this.a===null?"null":"undefined")+"' from JavaScript)"}}
A.eq.prototype={}
A.fI.prototype={
l(a){var s,r=this.b
if(r!=null)return r
r=this.a
s=r!==null&&typeof r==="object"?r.stack:null
return this.b=s==null?"":s},
$iaW:1}
A.cE.prototype={
l(a){var s=this.constructor,r=s==null?null:s.name
return"Closure '"+A.rg(r==null?"unknown":r)+"'"},
gjk(){return this},
$C:"$1",
$R:1,
$D:null}
A.iQ.prototype={$C:"$0",$R:0}
A.iR.prototype={$C:"$2",$R:2}
A.n4.prototype={}
A.mO.prototype={
l(a){var s=this.$static_name
if(s==null)return"Closure of unknown static method"
return"Closure '"+A.rg(s)+"'"}}
A.eb.prototype={
aw(a,b){if(b==null)return!1
if(this===b)return!0
if(!(b instanceof A.eb))return!1
return this.$_target===b.$_target&&this.a===b.a},
gY(a){return(A.rb(this.a)^A.hJ(this.$_target))>>>0},
l(a){return"Closure '"+this.$_name+"' of "+("Instance of '"+A.eV(this.a)+"'")}}
A.hN.prototype={
l(a){return"RuntimeError: "+this.a}}
A.c0.prototype={
gt(a){return this.a},
ga9(a){return this.a===0},
gaa(a){return this.a!==0},
gZ(){return new A.aB(this,A.E(this).i("aB<1>"))},
gaO(){return new A.b0(this,A.E(this).i("b0<2>"))},
gbY(){return new A.am(this,A.E(this).i("am<1,2>"))},
D(a){var s,r
if(typeof a=="string"){s=this.b
if(s==null)return!1
return s[a]!=null}else if(typeof a=="number"&&(a&0x3fffffff)===a){r=this.c
if(r==null)return!1
return r[a]!=null}else return this.iP(a)},
iP(a){var s=this.d
if(s==null)return!1
return this.cw(s[this.cv(a)],a)>=0},
X(a,b){b.a1(0,new A.lM(this))},
h(a,b){var s,r,q,p,o=null
if(typeof b=="string"){s=this.b
if(s==null)return o
r=s[b]
q=r==null?o:r.b
return q}else if(typeof b=="number"&&(b&0x3fffffff)===b){p=this.c
if(p==null)return o
r=p[b]
q=r==null?o:r.b
return q}else return this.iQ(b)},
iQ(a){var s,r,q=this.d
if(q==null)return null
s=q[this.cv(a)]
r=this.cw(s,a)
if(r<0)return null
return s[r].b},
k(a,b,c){var s,r,q=this
if(typeof b=="string"){s=q.b
q.dW(s==null?q.b=q.de():s,b,c)}else if(typeof b=="number"&&(b&0x3fffffff)===b){r=q.c
q.dW(r==null?q.c=q.de():r,b,c)}else q.iS(b,c)},
iS(a,b){var s,r,q,p=this,o=p.d
if(o==null)o=p.d=p.de()
s=p.cv(a)
r=o[s]
if(r==null)o[s]=[p.df(a,b)]
else{q=p.cw(r,a)
if(q>=0)r[q].b=b
else r.push(p.df(a,b))}},
J(a,b){var s,r,q=this
if(q.D(a)){s=q.h(0,a)
return s==null?A.E(q).y[1].a(s):s}r=b.$0()
q.k(0,a,r)
return r},
T(a,b){var s=this
if(typeof b=="string")return s.dU(s.b,b)
else if(typeof b=="number"&&(b&0x3fffffff)===b)return s.dU(s.c,b)
else return s.iR(b)},
iR(a){var s,r,q,p,o=this,n=o.d
if(n==null)return null
s=o.cv(a)
r=n[s]
q=o.cw(r,a)
if(q<0)return null
p=r.splice(q,1)[0]
o.dV(p)
if(r.length===0)delete n[s]
return p.b},
v(a){var s=this
if(s.a>0){s.b=s.c=s.d=s.e=s.f=null
s.a=0
s.dd()}},
a1(a,b){var s=this,r=s.e,q=s.r
while(r!=null){b.$2(r.a,r.b)
if(q!==s.r)throw A.c(A.aA(s))
r=r.c}},
dW(a,b,c){var s=a[b]
if(s==null)a[b]=this.df(b,c)
else s.b=c},
dU(a,b){var s
if(a==null)return null
s=a[b]
if(s==null)return null
this.dV(s)
delete a[b]
return s.b},
dd(){this.r=this.r+1&1073741823},
df(a,b){var s,r=this,q=new A.lQ(a,b)
if(r.e==null)r.e=r.f=q
else{s=r.f
s.toString
q.d=s
r.f=s.c=q}++r.a
r.dd()
return q},
dV(a){var s=this,r=a.d,q=a.c
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
l(a){return A.oW(this)},
de(){var s=Object.create(null)
s["<non-identifier-key>"]=s
delete s["<non-identifier-key>"]
return s}}
A.lM.prototype={
$2(a,b){this.a.k(0,a,b)},
$S(){return A.E(this.a).i("~(1,2)")}}
A.lQ.prototype={}
A.aB.prototype={
gt(a){return this.a.a},
ga9(a){return this.a.a===0},
gI(a){var s=this.a
return new A.aL(s,s.r,s.e,this.$ti.i("aL<1>"))},
E(a,b){return this.a.D(b)}}
A.aL.prototype={
gF(){return this.d},
p(){var s,r=this,q=r.a
if(r.b!==q.r)throw A.c(A.aA(q))
s=r.c
if(s==null){r.d=null
return!1}else{r.d=s.a
r.c=s.c
return!0}},
$ia1:1}
A.b0.prototype={
gt(a){return this.a.a},
ga9(a){return this.a.a===0},
gI(a){var s=this.a
return new A.an(s,s.r,s.e,this.$ti.i("an<1>"))}}
A.an.prototype={
gF(){return this.d},
p(){var s,r=this,q=r.a
if(r.b!==q.r)throw A.c(A.aA(q))
s=r.c
if(s==null){r.d=null
return!1}else{r.d=s.b
r.c=s.c
return!0}},
$ia1:1}
A.am.prototype={
gt(a){return this.a.a},
ga9(a){return this.a.a===0},
gI(a){var s=this.a
return new A.eG(s,s.r,s.e,this.$ti.i("eG<1,2>"))}}
A.eG.prototype={
gF(){var s=this.d
s.toString
return s},
p(){var s,r=this,q=r.a
if(r.b!==q.r)throw A.c(A.aA(q))
s=r.c
if(s==null){r.d=null
return!1}else{r.d=new A.aj(s.a,s.b,r.$ti.i("aj<1,2>"))
r.c=s.c
return!0}},
$ia1:1}
A.oi.prototype={
$1(a){return this.a(a)},
$S:53}
A.oj.prototype={
$2(a,b){return this.a(a,b)},
$S:73}
A.ok.prototype={
$1(a){return this.a(a)},
$S:36}
A.fG.prototype={
l(a){return this.f1(!1)},
f1(a){var s,r,q,p,o,n=this.hI(),m=this.en(),l=(a?"Record ":"")+"("
for(s=n.length,r="",q=0;q<s;++q,r=", "){l+=r
p=n[q]
if(typeof p=="string")l=l+p+": "
o=m[q]
l=a?l+A.qe(o):l+A.D(o)}l+=")"
return l.charCodeAt(0)==0?l:l},
hI(){var s,r=this.$s
while($.nM.length<=r)$.nM.push(null)
s=$.nM[r]
if(s==null){s=this.h7()
$.nM[r]=s}return s},
h7(){var s,r,q,p=this.$r,o=p.indexOf("("),n=p.substring(1,o),m=p.substring(o),l=m==="()"?0:m.replace(/[^,]/g,"").length+1,k=t.C,j=J.dz(l,k)
for(s=0;s<l;++s)j[s]=s
if(n!==""){r=n.split(",")
s=r.length
for(q=l;s>0;){--q;--s
j[q]=r[s]}}return A.q6(j,k)}}
A.ie.prototype={
en(){return[this.a,this.b]},
aw(a,b){if(b==null)return!1
return b instanceof A.ie&&this.$s===b.$s&&J.az(this.a,b.a)&&J.az(this.b,b.b)},
gY(a){return A.q7(this.$s,this.a,this.b,B.V)}}
A.dA.prototype={
l(a){return"RegExp/"+this.a+"/"+this.b.flags},
gez(){var s=this,r=s.c
if(r!=null)return r
r=s.b
return s.c=A.oQ(s.a,r.multiline,!r.ignoreCase,r.unicode,r.dotAll,"g")},
ghY(){var s=this,r=s.d
if(r!=null)return r
r=s.b
return s.d=A.oQ(s.a,r.multiline,!r.ignoreCase,r.unicode,r.dotAll,"y")},
h8(){var s,r=this.a
if(!B.a.E(r,"("))return!1
s=this.b.unicode?"u":""
return new RegExp("(?:)|"+r,s).exec("").length>1},
bp(a){var s=this.b.exec(a)
if(s==null)return null
return new A.dZ(s)},
f5(a,b){return new A.i0(this,b,0)},
ef(a,b){var s,r=this.gez()
r.lastIndex=b
s=r.exec(a)
if(s==null)return null
return new A.dZ(s)},
ee(a,b){var s,r=this.ghY()
r.lastIndex=b
s=r.exec(a)
if(s==null)return null
return new A.dZ(s)},
dH(a,b,c){if(c<0||c>b.length)throw A.c(A.ax(c,0,b.length,null,null))
return this.ee(b,c)}}
A.dZ.prototype={
gcS(){return this.b.index},
gcp(){var s=this.b
return s.index+s[0].length},
h(a,b){return this.b[b]},
$idD:1,
$ieY:1}
A.i0.prototype={
gI(a){return new A.i1(this.a,this.b,this.c)}}
A.i1.prototype={
gF(){var s=this.d
return s==null?t.cz.a(s):s},
p(){var s,r,q,p,o,n,m=this,l=m.b
if(l==null)return!1
s=m.c
r=l.length
if(s<=r){q=m.a
p=q.ef(l,s)
if(p!=null){m.d=p
o=p.gcp()
if(p.b.index===o){s=!1
if(q.b.unicode){q=m.c
n=q+1
if(n<r){r=l.charCodeAt(q)
if(r>=55296&&r<=56319){s=l.charCodeAt(n)
s=s>=56320&&s<=57343}}}o=(s?o+1:o)+1}m.c=o
return!0}}m.b=m.d=null
return!1},
$ia1:1}
A.dT.prototype={
gcp(){return this.a+this.c.length},
h(a,b){if(b!==0)throw A.c(A.mG(b,null))
return this.c},
$idD:1,
gcS(){return this.a}}
A.ij.prototype={
gI(a){return new A.ik(this.a,this.b,this.c)},
gH(a){var s=this.b,r=this.a.indexOf(s,this.c)
if(r>=0)return new A.dT(r,s)
throw A.c(A.bZ())}}
A.ik.prototype={
p(){var s,r,q=this,p=q.c,o=q.b,n=o.length,m=q.a,l=m.length
if(p+n>l){q.d=null
return!1}s=m.indexOf(o,p)
if(s<0){q.c=l+1
q.d=null
return!1}r=s+n
q.d=new A.dT(s,o)
q.c=r===q.c?r+1:r
return!0},
gF(){var s=this.d
s.toString
return s},
$ia1:1}
A.nl.prototype={
eO(){var s=this.b
if(s===this)throw A.c(new A.cO("Local '' has not been initialized."))
return s}}
A.dF.prototype={
gak(a){return B.cW},
cj(a,b,c){A.d3(a,b,c)
return c==null?new Uint8Array(a,b):new Uint8Array(a,b,c)},
f9(a){return this.cj(a,0,null)},
f8(a,b,c){A.d3(a,b,c)
return new Int32Array(a,b,c)},
f7(a,b,c){A.d3(a,b,c)
return new Float64Array(a,b,c)},
f6(a,b,c){var s
A.d3(a,b,c)
s=new DataView(a,b,c)
return s},
$iac:1}
A.eM.prototype={
gai(a){if(((a.$flags|0)&2)!==0)return new A.nV(a.buffer)
else return a.buffer},
hQ(a,b,c,d){var s=A.ax(b,0,c,d,null)
throw A.c(s)},
e2(a,b,c,d){if(b>>>0!==b||b>c)this.hQ(a,b,c,d)}}
A.nV.prototype={
cj(a,b,c){var s=A.tw(this.a,b,c)
s.$flags=3
return s},
f9(a){return this.cj(0,0,null)},
f8(a,b,c){var s=A.tv(this.a,b,c)
s.$flags=3
return s},
f7(a,b,c){var s=A.tu(this.a,b,c)
s.$flags=3
return s},
f6(a,b,c){var s=A.tt(this.a,b,c)
s.$flags=3
return s}}
A.eJ.prototype={
gak(a){return B.cX},
c0(a,b){throw A.c(A.Y("Int64 accessor not supported by dart2js."))},
hO(a,b,c){return a.getUint16(b,c)},
c2(a,b,c){throw A.c(A.Y("Int64 accessor not supported by dart2js."))},
io(a,b,c,d){return a.setUint16(b,c,d)},
fO(a,b,c){throw A.c(A.Y("Uint64 accessor not supported by dart2js."))},
$iac:1}
A.dG.prototype={
gt(a){return a.length},
eY(a,b,c,d,e){var s,r,q=a.length
this.e2(a,b,q,"start")
this.e2(a,c,q,"end")
if(b>c)throw A.c(A.ax(b,0,c,null,null))
s=c-b
if(e<0)throw A.c(A.bl(e,null))
r=d.length
if(r-e<s)throw A.c(A.fg("Not enough elements"))
if(e!==0||r!==s)d=d.subarray(e,e+s)
a.set(d,b)},
$iaP:1,
$ibf:1}
A.cn.prototype={
h(a,b){A.cb(b,a,a.length)
return a[b]},
k(a,b,c){a.$flags&2&&A.i(a)
A.cb(b,a,a.length)
a[b]=c},
aG(a,b,c,d,e){a.$flags&2&&A.i(a,5)
if(t.d4.b(d)){this.eY(a,b,c,d,e)
return}this.dS(a,b,c,d,e)},
a8(a,b,c,d){return this.aG(a,b,c,d,0)},
$iH:1,
$it:1}
A.bg.prototype={
k(a,b,c){a.$flags&2&&A.i(a)
A.cb(b,a,a.length)
a[b]=c},
aG(a,b,c,d,e){a.$flags&2&&A.i(a,5)
if(t.eB.b(d)){this.eY(a,b,c,d,e)
return}this.dS(a,b,c,d,e)},
a8(a,b,c,d){return this.aG(a,b,c,d,0)},
$iH:1,
$it:1}
A.hu.prototype={
gak(a){return B.cY},
$iac:1}
A.eK.prototype={
gak(a){return B.cZ},
$iac:1}
A.hv.prototype={
gak(a){return B.d_},
h(a,b){A.cb(b,a,a.length)
return a[b]},
$iac:1}
A.eL.prototype={
gak(a){return B.d0},
h(a,b){A.cb(b,a,a.length)
return a[b]},
$iac:1}
A.hw.prototype={
gak(a){return B.d1},
h(a,b){A.cb(b,a,a.length)
return a[b]},
$iac:1}
A.hx.prototype={
gak(a){return B.d3},
h(a,b){A.cb(b,a,a.length)
return a[b]},
$iac:1}
A.hy.prototype={
gak(a){return B.d4},
h(a,b){A.cb(b,a,a.length)
return a[b]},
$iac:1}
A.eN.prototype={
gak(a){return B.d5},
gt(a){return a.length},
h(a,b){A.cb(b,a,a.length)
return a[b]},
$iac:1}
A.eO.prototype={
gak(a){return B.d6},
gt(a){return a.length},
h(a,b){A.cb(b,a,a.length)
return a[b]},
bj(a,b,c){return new Uint8Array(a.subarray(b,A.pe(b,c,a.length)))},
$iac:1,
$iba:1}
A.fC.prototype={}
A.fD.prototype={}
A.fE.prototype={}
A.fF.prototype={}
A.bD.prototype={
i(a){return A.fN(v.typeUniverse,this,a)},
au(a){return A.qG(v.typeUniverse,this,a)}}
A.ia.prototype={}
A.nT.prototype={
l(a){return A.bj(this.a,null)}}
A.i9.prototype={
l(a){return this.a}}
A.fJ.prototype={$ic7:1}
A.ni.prototype={
$1(a){var s=this.a,r=s.a
s.a=null
r.$0()},
$S:42}
A.nh.prototype={
$1(a){var s,r
this.a.a=a
s=this.b
r=this.c
s.firstChild?s.removeChild(r):s.appendChild(r)},
$S:76}
A.nj.prototype={
$0(){this.a.$0()},
$S:12}
A.nk.prototype={
$0(){this.a.$0()},
$S:12}
A.im.prototype={
fX(a,b){if(self.setTimeout!=null)self.setTimeout(A.fU(new A.nS(this,b),0),a)
else throw A.c(A.Y("`setTimeout()` not found."))},
fY(a,b){if(self.setTimeout!=null)self.setInterval(A.fU(new A.nR(this,a,Date.now(),b),0),a)
else throw A.c(A.Y("Periodic timer."))}}
A.nS.prototype={
$0(){this.a.c=1
this.b.$0()},
$S:2}
A.nR.prototype={
$0(){var s,r=this,q=r.a,p=q.c+1,o=r.b
if(o>0){s=Date.now()-r.c
if(s>(p+1)*o)p=B.c.aY(s,o)}q.c=p
r.d.$1(q)},
$S:12}
A.i2.prototype={
fb(a){var s,r=this
if(a==null)a=r.$ti.c.a(a)
if(!r.b)r.a.dY(a)
else{s=r.a
if(r.$ti.i("b7<1>").b(a))s.e_(a)
else s.c8(a)}},
fc(a,b){var s=this.a
if(this.b)s.bk(new A.aK(a,b))
else s.c5(new A.aK(a,b))}}
A.o_.prototype={
$1(a){return this.a.$2(0,a)},
$S:77}
A.o0.prototype={
$2(a,b){this.a.$2(1,new A.eq(a,b))},
$S:80}
A.ob.prototype={
$2(a,b){this.a(a,b)},
$S:120}
A.ca.prototype={
gF(){return this.b},
ie(a,b){var s,r,q
a=a
b=b
s=this.a
for(;;)try{r=s(this,a,b)
return r}catch(q){b=q
a=1}},
p(){var s,r,q,p,o=this,n=null,m=0
for(;;){s=o.d
if(s!=null)try{if(s.p()){o.b=s.gF()
return!0}else o.d=null}catch(r){n=r
m=1
o.d=null}q=o.ie(m,n)
if(1===q)return!0
if(0===q){o.b=null
p=o.e
if(p==null||p.length===0){o.a=A.qB
return!1}o.a=p.pop()
m=0
n=null
continue}if(2===q){m=0
n=null
continue}if(3===q){n=o.c
o.c=null
p=o.e
if(p==null||p.length===0){o.b=null
o.a=A.qB
throw n
return!1}o.a=p.pop()
m=1
continue}throw A.c(A.fg("sync*"))}return!1},
jo(a){var s,r,q=this
if(a instanceof A.cx){s=a.a()
r=q.e
if(r==null)r=q.e=[]
r.push(q.a)
q.a=s
return 2}else{q.d=J.au(a)
return 2}},
$ia1:1}
A.cx.prototype={
gI(a){return new A.ca(this.a(),this.$ti.i("ca<1>"))}}
A.aK.prototype={
l(a){return A.D(this.a)},
$iah:1,
gbI(){return this.b}}
A.fu.prototype={
ghX(){return this.c<4},
h0(){if((this.c&4)!==0)return new A.cq("Cannot add new events after calling close")
return new A.cq("Cannot add new events while doing an addStream")},
R(a,b){if(!this.ghX())throw A.c(this.h0())
this.ik(b)},
$ifh:1}
A.fs.prototype={
ik(a){var s
for(s=this.d;!1;s=s.gjn())s.jl(new A.i7())}}
A.ji.prototype={
$0(){var s,r,q,p,o,n,m,l=null
try{l=this.a.$0()}catch(q){s=A.aU(q)
r=A.bP(q)
p=s
o=r
n=A.pi(p,o)
if(n==null)p=new A.aK(p,o)
else p=n
this.b.bk(p)
return}p=this.b
o=l
if(p.$ti.i("b7<1>").b(o))A.nw(o,p,!0)
else{m=p.bV()
p.a=8
p.c=o
A.cX(p,m)}},
$S:2}
A.jk.prototype={
$2(a,b){var s=this,r=s.a,q=--r.b
if(r.a!=null){r.a=null
r.d=a
r.c=b
if(q===0||s.c)s.d.bk(new A.aK(a,b))}else if(q===0&&!s.c){q=r.d
q.toString
r=r.c
r.toString
s.d.bk(new A.aK(q,r))}},
$S:121}
A.jj.prototype={
$1(a){var s,r,q,p,o,n,m=this,l=m.a,k=--l.b,j=l.a
if(j!=null){J.aX(j,m.b,a)
if(J.az(k,0)){l=m.d
s=A.a([],l.i("C<0>"))
for(q=j,p=q.length,o=0;o<q.length;q.length===p||(0,A.n)(q),++o){r=q[o]
n=r
if(n==null)n=l.a(n)
J.ae(s,n)}m.c.c8(s)}}else if(J.az(k,0)&&!m.f){s=l.d
s.toString
l=l.c
l.toString
m.c.bk(new A.aK(s,l))}},
$S(){return this.d.i("aE(0)")}}
A.i4.prototype={
fc(a,b){var s=this.a
if((s.a&30)!==0)throw A.c(A.fg("Future already completed"))
s.c5(A.v4(a,b))}}
A.ft.prototype={
fb(a){var s=this.a
if((s.a&30)!==0)throw A.c(A.fg("Future already completed"))
s.dY(a)}}
A.dY.prototype={
j0(a){if((this.c&15)!==6)return!0
return this.b.b.bH(this.d,a.a,t.y,t.C)},
iL(a){var s,r=this.e,q=null,p=t.z,o=t.C,n=a.a,m=this.b.b
if(t.ag.b(r))q=m.fz(r,n,a.b,p,o,t.l)
else q=m.bH(r,n,p,o)
try{p=q
return p}catch(s){if(t.eK.b(A.aU(s))){if((this.c&1)!==0)throw A.c(A.bl("The error handler of Future.then must return a value of the returned future's type","onError"))
throw A.c(A.bl("The error handler of Future.catchError must return a value of the future's type","onError"))}else throw s}}}
A.ad.prototype={
cI(a,b,c){var s,r,q=$.V
if(q===B.m){if(b!=null&&!t.ag.b(b)&&!t.bI.b(b))throw A.c(A.oB(b,"onError",u.c))}else{a=q.cH(a,c.i("0/"),this.$ti.c)
if(b!=null)b=A.vp(b,q)}s=new A.ad($.V,c.i("ad<0>"))
r=b==null?1:3
this.cT(new A.dY(s,r,a,b,this.$ti.i("@<1>").au(c).i("dY<1,2>")))
return s},
f0(a,b,c){var s=new A.ad($.V,c.i("ad<0>"))
this.cT(new A.dY(s,19,a,b,this.$ti.i("@<1>").au(c).i("dY<1,2>")))
return s},
im(a){this.a=this.a&1|16
this.c=a},
c6(a){this.a=a.a&30|this.a&1
this.c=a.c},
cT(a){var s=this,r=s.a
if(r<=3){a.a=s.c
s.c=a}else{if((r&4)!==0){r=s.c
if((r.a&24)===0){r.cT(a)
return}s.c6(r)}s.b.bh(new A.nt(s,a))}},
eL(a){var s,r,q,p,o,n=this,m={}
m.a=a
if(a==null)return
s=n.a
if(s<=3){r=n.c
n.c=a
if(r!=null){q=a.a
for(p=a;q!=null;p=q,q=o)o=q.a
p.a=r}}else{if((s&4)!==0){s=n.c
if((s.a&24)===0){s.eL(a)
return}n.c6(s)}m.a=n.cf(a)
n.b.bh(new A.ny(m,n))}},
bV(){var s=this.c
this.c=null
return this.cf(s)},
cf(a){var s,r,q
for(s=a,r=null;s!=null;r=s,s=q){q=s.a
s.a=r}return r},
c8(a){var s=this,r=s.bV()
s.a=8
s.c=a
A.cX(s,r)},
h6(a){var s,r,q,p=this
if((a.a&16)!==0){s=p.b
r=a.b
s=!(s===r||s.gb3()===r.gb3())}else s=!1
if(s)return
q=p.bV()
p.c6(a)
A.cX(p,q)},
bk(a){var s=this.bV()
this.im(a)
A.cX(this,s)},
dY(a){if(this.$ti.i("b7<1>").b(a)){this.e_(a)
return}this.h3(a)},
h3(a){this.a^=2
this.b.bh(new A.nv(this,a))},
e_(a){A.nw(a,this,!1)
return},
c5(a){this.a^=2
this.b.bh(new A.nu(this,a))},
$ib7:1}
A.nt.prototype={
$0(){A.cX(this.a,this.b)},
$S:2}
A.ny.prototype={
$0(){A.cX(this.b,this.a.a)},
$S:2}
A.nx.prototype={
$0(){A.nw(this.a.a,this.b,!0)},
$S:2}
A.nv.prototype={
$0(){this.a.c8(this.b)},
$S:2}
A.nu.prototype={
$0(){this.a.bk(this.b)},
$S:2}
A.nB.prototype={
$0(){var s,r,q,p,o,n,m,l,k=this,j=null
try{q=k.a.a
j=q.b.b.bG(q.d,t.z)}catch(p){s=A.aU(p)
r=A.bP(p)
if(k.c&&k.b.a.c.a===s){q=k.a
q.c=k.b.a.c}else{q=s
o=r
if(o==null)o=A.iz(q)
n=k.a
n.c=new A.aK(q,o)
q=n}q.b=!0
return}if(j instanceof A.ad&&(j.a&24)!==0){if((j.a&16)!==0){q=k.a
q.c=j.c
q.b=!0}return}if(j instanceof A.ad){m=k.b.a
l=new A.ad(m.b,m.$ti)
j.cI(new A.nC(l,m),new A.nD(l),t.H)
q=k.a
q.c=l
q.b=!1}},
$S:2}
A.nC.prototype={
$1(a){this.a.h6(this.b)},
$S:42}
A.nD.prototype={
$2(a,b){this.a.bk(new A.aK(a,b))},
$S:68}
A.nA.prototype={
$0(){var s,r,q,p,o,n
try{q=this.a
p=q.a
o=p.$ti
q.c=p.b.b.bH(p.d,this.b,o.i("2/"),o.c)}catch(n){s=A.aU(n)
r=A.bP(n)
q=s
p=r
if(p==null)p=A.iz(q)
o=this.a
o.c=new A.aK(q,p)
o.b=!0}},
$S:2}
A.nz.prototype={
$0(){var s,r,q,p,o,n,m,l=this
try{s=l.a.a.c
p=l.b
if(p.a.j0(s)&&p.a.e!=null){p.c=p.a.iL(s)
p.b=!1}}catch(o){r=A.aU(o)
q=A.bP(o)
p=l.a.a.c
if(p.a===r){n=l.b
n.c=p
p=n}else{p=r
n=q
if(n==null)n=A.iz(p)
m=l.b
m.c=new A.aK(p,n)
p=m}p.b=!0}},
$S:2}
A.i3.prototype={}
A.i8.prototype={}
A.i7.prototype={}
A.ii.prototype={}
A.aT.prototype={}
A.ip.prototype={
dj(a,b,c){var s,r,q,p,o,n,m,l,k=this.gd5(),j=k.a
if(j===B.m){A.o4(b,c)
return}s=k.b
r=j.gaK()
m=j.gfq()
m.toString
q=m
p=$.V
try{$.V=q
s.$5(j,r,a,b,c)
$.V=p}catch(l){o=A.aU(l)
n=A.bP(l)
$.V=p
m=b===o?c:n
q.dj(j,o,m)}},
$iJ:1}
A.i6.prototype={
gea(){var s=this.at
return s==null?this.at=new A.e_(this):s},
gaK(){return this.ax.gea()},
gb3(){return this.as.a},
dL(a){var s,r,q
try{this.bG(a,t.H)}catch(q){s=A.aU(q)
r=A.bP(q)
this.dj(this,s,r)}},
dr(a,b){return new A.no(this,this.cG(a,b),b)},
fa(a,b,c){return new A.np(this,this.cH(a,b,c),c,b)},
ds(a){return new A.nn(this,this.cG(a,t.H))},
h(a,b){var s,r=this.ay,q=r.h(0,b)
if(q!=null||r.D(b))return q
s=this.ax.h(0,b)
if(s!=null)r.k(0,b,s)
return s},
dB(a,b){this.dj(this,a,b)},
fl(a,b){var s=this.Q,r=s.a
return s.b.$5(r,r.gaK(),this,a,b)},
bG(a){var s=this.a,r=s.a
return s.b.$4(r,r.gaK(),this,a)},
bH(a,b){var s=this.b,r=s.a
return s.b.$5(r,r.gaK(),this,a,b)},
fz(a,b,c){var s=this.c,r=s.a
return s.b.$6(r,r.gaK(),this,a,b,c)},
cG(a){var s=this.d,r=s.a
return s.b.$4(r,r.gaK(),this,a)},
cH(a){var s=this.e,r=s.a
return s.b.$4(r,r.gaK(),this,a)},
dJ(a){var s=this.f,r=s.a
return s.b.$4(r,r.gaK(),this,a)},
fh(a,b){var s=this.r,r=s.a
if(r===B.m)return null
return s.b.$5(r,r.gaK(),this,a,b)},
bh(a){var s=this.w,r=s.a
return s.b.$4(r,r.gaK(),this,a)},
ft(a){var s=this.z,r=s.a
return s.b.$4(r,r.gaK(),this,a)},
geT(){return this.a},
geV(){return this.b},
geU(){return this.c},
geQ(){return this.d},
geR(){return this.e},
geP(){return this.f},
gec(){return this.r},
gdl(){return this.w},
ge7(){return this.x},
ge6(){return this.y},
geM(){return this.z},
gel(){return this.Q},
gd5(){return this.as},
gfq(){return this.ax},
gey(){return this.ay}}
A.no.prototype={
$0(){return this.a.bG(this.b,this.c)},
$S(){return this.c.i("0()")}}
A.np.prototype={
$1(a){var s=this
return s.a.bH(s.b,a,s.d,s.c)},
$S(){return this.d.i("@<0>").au(this.c).i("1(2)")}}
A.nn.prototype={
$0(){return this.a.dL(this.b)},
$S:2}
A.ih.prototype={
geT(){return B.dh},
geV(){return B.dj},
geU(){return B.di},
geQ(){return B.dg},
geR(){return B.db},
geP(){return B.dl},
gec(){return B.dd},
gdl(){return B.dk},
ge7(){return B.dc},
ge6(){return B.da},
geM(){return B.df},
gel(){return B.de},
gd5(){return B.d9},
gfq(){return null},
gey(){return $.rx()},
gea(){var s=$.nN
return s==null?$.nN=new A.e_(this):s},
gaK(){var s=$.nN
return s==null?$.nN=new A.e_(this):s},
gb3(){return this},
dL(a){var s,r,q
try{if(B.m===$.V){a.$0()
return}A.o6(null,null,this,a)}catch(q){s=A.aU(q)
r=A.bP(q)
A.o4(s,r)}},
dr(a,b){return new A.nP(this,a,b)},
fa(a,b,c){return new A.nQ(this,a,c,b)},
ds(a){return new A.nO(this,a)},
h(a,b){return null},
dB(a,b){A.o4(a,b)},
fl(a,b){return A.qS(null,null,this,a,b)},
bG(a){if($.V===B.m)return a.$0()
return A.o6(null,null,this,a)},
bH(a,b){if($.V===B.m)return a.$1(b)
return A.po(null,null,this,a,b)},
fz(a,b,c){if($.V===B.m)return a.$2(b,c)
return A.pn(null,null,this,a,b,c)},
cG(a){return a},
cH(a){return a},
dJ(a){return a},
fh(a,b){return null},
bh(a){A.o7(null,null,this,a)},
ft(a){A.op(a)}}
A.nP.prototype={
$0(){return this.a.bG(this.b,this.c)},
$S(){return this.c.i("0()")}}
A.nQ.prototype={
$1(a){var s=this
return s.a.bH(s.b,a,s.d,s.c)},
$S(){return this.d.i("@<0>").au(this.c).i("1(2)")}}
A.nO.prototype={
$0(){return this.a.dL(this.b)},
$S:2}
A.e_.prototype={$iak:1}
A.o5.prototype={
$0(){A.t5(this.a,this.b)},
$S:2}
A.iq.prototype={$ip6:1}
A.fx.prototype={
gt(a){return this.a},
ga9(a){return this.a===0},
gaa(a){return this.a!==0},
gZ(){return new A.cY(this,A.E(this).i("cY<1>"))},
gaO(){var s=A.E(this)
return A.oX(new A.cY(this,s.i("cY<1>")),new A.nE(this),s.c,s.y[1])},
D(a){var s,r
if(typeof a=="string"&&a!=="__proto__"){s=this.b
return s==null?!1:s[a]!=null}else if(typeof a=="number"&&(a&1073741823)===a){r=this.c
return r==null?!1:r[a]!=null}else return this.ha(a)},
ha(a){var s=this.d
if(s==null)return!1
return this.b8(this.em(s,a),a)>=0},
h(a,b){var s,r,q
if(typeof b=="string"&&b!=="__proto__"){s=this.b
r=s==null?null:A.p7(s,b)
return r}else if(typeof b=="number"&&(b&1073741823)===b){q=this.c
r=q==null?null:A.p7(q,b)
return r}else return this.hM(b)},
hM(a){var s,r,q=this.d
if(q==null)return null
s=this.em(q,a)
r=this.b8(s,a)
return r<0?null:s[r+1]},
k(a,b,c){var s,r,q=this
if(typeof b=="string"&&b!=="__proto__"){s=q.b
q.e4(s==null?q.b=A.p8():s,b,c)}else if(typeof b=="number"&&(b&1073741823)===b){r=q.c
q.e4(r==null?q.c=A.p8():r,b,c)}else q.il(b,c)},
il(a,b){var s,r,q,p=this,o=p.d
if(o==null)o=p.d=A.p8()
s=p.bl(a)
r=o[s]
if(r==null){A.p9(o,s,[a,b]);++p.a
p.e=null}else{q=p.b8(r,a)
if(q>=0)r[q+1]=b
else{r.push(a,b);++p.a
p.e=null}}},
J(a,b){var s,r,q=this
if(q.D(a)){s=q.h(0,a)
return s==null?A.E(q).y[1].a(s):s}r=b.$0()
q.k(0,a,r)
return r},
T(a,b){var s=this
if(typeof b=="string"&&b!=="__proto__")return s.bU(s.b,b)
else if(typeof b=="number"&&(b&1073741823)===b)return s.bU(s.c,b)
else return s.dk(b)},
dk(a){var s,r,q,p,o=this,n=o.d
if(n==null)return null
s=o.bl(a)
r=n[s]
q=o.b8(r,a)
if(q<0)return null;--o.a
o.e=null
p=r.splice(q,2)[1]
if(0===r.length)delete n[s]
return p},
a1(a,b){var s,r,q,p,o,n=this,m=n.e5()
for(s=m.length,r=A.E(n).y[1],q=0;q<s;++q){p=m[q]
o=n.h(0,p)
b.$2(p,o==null?r.a(o):o)
if(m!==n.e)throw A.c(A.aA(n))}},
e5(){var s,r,q,p,o,n,m,l,k,j,i=this,h=i.e
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
e4(a,b,c){if(a[b]==null){++this.a
this.e=null}A.p9(a,b,c)},
bU(a,b){var s
if(a!=null&&a[b]!=null){s=A.p7(a,b)
delete a[b];--this.a
this.e=null
return s}else return null},
bl(a){return J.by(a)&1073741823},
em(a,b){return a[this.bl(b)]},
b8(a,b){var s,r
if(a==null)return-1
s=a.length
for(r=0;r<s;r+=2)if(J.az(a[r],b))return r
return-1}}
A.nE.prototype={
$1(a){var s=this.a,r=s.h(0,a)
return r==null?A.E(s).y[1].a(r):r},
$S(){return A.E(this.a).i("2(1)")}}
A.cY.prototype={
gt(a){return this.a.a},
ga9(a){return this.a.a===0},
gaa(a){return this.a.a!==0},
gI(a){var s=this.a
return new A.fy(s,s.e5(),this.$ti.i("fy<1>"))},
E(a,b){return this.a.D(b)}}
A.fy.prototype={
gF(){var s=this.d
return s==null?this.$ti.c.a(s):s},
p(){var s=this,r=s.b,q=s.c,p=s.a
if(r!==p.e)throw A.c(A.aA(p))
else if(q>=r.length){s.d=null
return!1}else{s.d=r[q]
s.c=q+1
return!0}},
$ia1:1}
A.d0.prototype={
gI(a){var s=this,r=new A.c9(s,s.r,A.E(s).i("c9<1>"))
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
return r[b]!=null}else return this.h9(b)},
h9(a){var s=this.d
if(s==null)return!1
return this.b8(s[this.bl(a)],a)>=0},
gH(a){var s=this.e
if(s==null)throw A.c(A.fg("No elements"))
return s.a},
R(a,b){var s,r,q=this
if(typeof b=="string"&&b!=="__proto__"){s=q.b
return q.e3(s==null?q.b=A.pa():s,b)}else if(typeof b=="number"&&(b&1073741823)===b){r=q.c
return q.e3(r==null?q.c=A.pa():r,b)}else return q.fZ(b)},
fZ(a){var s,r,q=this,p=q.d
if(p==null)p=q.d=A.pa()
s=q.bl(a)
r=p[s]
if(r==null)p[s]=[q.cX(a)]
else{if(q.b8(r,a)>=0)return!1
r.push(q.cX(a))}return!0},
T(a,b){var s=this
if(typeof b=="string"&&b!=="__proto__")return s.bU(s.b,b)
else if(typeof b=="number"&&(b&1073741823)===b)return s.bU(s.c,b)
else return s.dk(b)},
dk(a){var s,r,q,p,o=this,n=o.d
if(n==null)return!1
s=o.bl(a)
r=n[s]
q=o.b8(r,a)
if(q<0)return!1
p=r.splice(q,1)[0]
if(0===r.length)delete n[s]
o.f2(p)
return!0},
v(a){var s=this
if(s.a>0){s.b=s.c=s.d=s.e=s.f=null
s.a=0
s.cW()}},
e3(a,b){if(a[b]!=null)return!1
a[b]=this.cX(b)
return!0},
bU(a,b){var s
if(a==null)return!1
s=a[b]
if(s==null)return!1
this.f2(s)
delete a[b]
return!0},
cW(){this.r=this.r+1&1073741823},
cX(a){var s,r=this,q=new A.nL(a)
if(r.e==null)r.e=r.f=q
else{s=r.f
s.toString
q.c=s
r.f=s.b=q}++r.a
r.cW()
return q},
f2(a){var s=this,r=a.c,q=a.b
if(r==null)s.e=q
else r.b=q
if(q==null)s.f=r
else q.c=r;--s.a
s.cW()},
bl(a){return J.by(a)&1073741823},
b8(a,b){var s,r
if(a==null)return-1
s=a.length
for(r=0;r<s;++r)if(J.az(a[r].a,b))return r
return-1}}
A.nL.prototype={}
A.c9.prototype={
gF(){var s=this.d
return s==null?this.$ti.c.a(s):s},
p(){var s=this,r=s.c,q=s.a
if(s.b!==q.r)throw A.c(A.aA(q))
else if(r==null){s.d=null
return!1}else{s.d=r.a
s.c=r.b
return!0}},
$ia1:1}
A.jw.prototype={
$2(a,b){this.a.k(0,this.b.a(a),this.c.a(b))},
$S:4}
A.lR.prototype={
$2(a,b){this.a.k(0,this.b.a(a),this.c.a(b))},
$S:4}
A.a2.prototype={
gI(a){return new A.cQ(a,this.gt(a),A.bQ(a).i("cQ<a2.E>"))},
an(a,b){return this.h(a,b)},
ga9(a){return this.gt(a)===0},
gaa(a){return this.gt(a)!==0},
gH(a){if(this.gt(a)===0)throw A.c(A.bZ())
return this.h(a,0)},
gV(a){if(this.gt(a)===0)throw A.c(A.bZ())
return this.h(a,this.gt(a)-1)},
E(a,b){var s,r=this.gt(a)
for(s=0;s<r;++s){this.h(a,s)
if(r!==this.gt(a))throw A.c(A.aA(a))}return!1},
cq(a,b){var s,r=this.gt(a)
for(s=0;s<r;++s){if(!b.$1(this.h(a,s)))return!1
if(r!==this.gt(a))throw A.c(A.aA(a))}return!0},
b1(a,b){var s,r=this.gt(a)
for(s=0;s<r;++s){if(b.$1(this.h(a,s)))return!0
if(r!==this.gt(a))throw A.c(A.aA(a))}return!1},
S(a,b){var s
if(this.gt(a)===0)return""
s=A.p4("",a,b)
return s.charCodeAt(0)==0?s:s},
bd(a,b,c){return new A.h(a,b,A.bQ(a).i("@<a2.E>").au(c).i("h<1,2>"))},
fj(a,b,c){return new A.bX(a,b,A.bQ(a).i("@<a2.E>").au(c).i("bX<1,2>"))},
aQ(a,b){var s,r,q,p,o=this
if(o.gt(a)===0){s=J.oP(0,A.bQ(a).i("a2.E"))
return s}r=o.h(a,0)
q=A.a9(o.gt(a),r,!0,A.bQ(a).i("a2.E"))
for(p=1;p<o.gt(a);++p)q[p]=o.h(a,p)
return q},
aN(a){return this.aQ(a,!0)},
R(a,b){var s=this.gt(a)
this.st(a,s+1)
this.k(a,s,b)},
T(a,b){var s
for(s=0;s<this.gt(a);++s)this.h(a,s)
return!1},
ar(a,b){A.hP(a,0,this.gt(a)-1,b)},
bD(a,b,c,d){var s
A.c4(b,c,this.gt(a))
for(s=b;s<c;++s)this.k(a,s,d)},
aG(a,b,c,d,e){var s,r,q
A.c4(b,c,this.gt(a))
s=c-b
if(s===0)return
A.eX(e,"skipCount")
r=J.X(d)
if(e+s>r.gt(d))throw A.c(A.pZ())
if(e<b)for(q=s-1;q>=0;--q)this.k(a,b+q,r.h(d,e+q))
else for(q=0;q<s;++q)this.k(a,b+q,r.h(d,e+q))},
a8(a,b,c,d){return this.aG(a,b,c,d,0)},
aj(a,b,c){this.a8(a,b,b+c.length,c)},
l(a){return A.oO(a,"[","]")},
$iH:1,
$it:1}
A.aa.prototype={
a1(a,b){var s,r,q,p
for(s=this.gZ(),s=s.gI(s),r=A.E(this).i("aa.V");s.p();){q=s.gF()
p=this.h(0,q)
b.$2(q,p==null?r.a(p):p)}},
J(a,b){var s,r=this
if(r.D(a)){s=r.h(0,a)
return s==null?A.E(r).i("aa.V").a(s):s}s=b.$0()
r.k(0,a,s)
return s},
gbY(){return this.gZ().bd(0,new A.lS(this),A.E(this).i("aj<aa.K,aa.V>"))},
dG(a,b,c,d){var s,r,q,p,o,n=A.o(c,d)
for(s=this.gZ(),s=s.gI(s),r=A.E(this).i("aa.V");s.p();){q=s.gF()
p=this.h(0,q)
o=b.$2(q,p==null?r.a(p):p)
n.k(0,o.a,o.b)}return n},
jb(a,b){var s,r,q,p,o=this,n=A.E(o),m=A.a([],n.i("C<aa.K>"))
for(s=o.gZ(),s=s.gI(s),n=n.i("aa.V");s.p();){r=s.gF()
q=o.h(0,r)
if(b.$2(r,q==null?n.a(q):q))m.push(r)}for(n=m.length,p=0;p<m.length;m.length===n||(0,A.n)(m),++p)o.T(0,m[p])},
D(a){return this.gZ().E(0,a)},
gt(a){var s=this.gZ()
return s.gt(s)},
ga9(a){var s=this.gZ()
return s.ga9(s)},
gaa(a){var s=this.gZ()
return s.gaa(s)},
gaO(){return new A.fA(this,A.E(this).i("fA<aa.K,aa.V>"))},
l(a){return A.oW(this)},
$iw:1}
A.lS.prototype={
$1(a){var s=this.a,r=s.h(0,a)
if(r==null)r=A.E(s).i("aa.V").a(r)
return new A.aj(a,r,A.E(s).i("aj<aa.K,aa.V>"))},
$S(){return A.E(this.a).i("aj<aa.K,aa.V>(aa.K)")}}
A.lT.prototype={
$2(a,b){var s,r=this.a
if(!r.a)this.b.a+=", "
r.a=!1
r=this.b
s=A.D(a)
r.a=(r.a+=s)+": "
s=A.D(b)
r.a+=s},
$S:47}
A.fA.prototype={
gt(a){var s=this.a
return s.gt(s)},
ga9(a){var s=this.a
return s.ga9(s)},
gaa(a){var s=this.a
return s.gaa(s)},
gH(a){var s=this.a,r=s.gZ()
r=s.h(0,r.gH(r))
return r==null?this.$ti.y[1].a(r):r},
gI(a){var s=this.a,r=s.gZ()
return new A.fB(r.gI(r),s,this.$ti.i("fB<1,2>"))}}
A.fB.prototype={
p(){var s=this,r=s.a
if(r.p()){s.c=s.b.h(0,r.gF())
return!0}s.c=null
return!1},
gF(){var s=this.c
return s==null?this.$ti.y[1].a(s):s},
$ia1:1}
A.c5.prototype={
ga9(a){return this.gt(this)===0},
gaa(a){return this.gt(this)!==0},
X(a,b){var s
for(s=J.au(b);s.p();)this.R(0,s.gF())},
aQ(a,b){var s=A.r(this,A.E(this).c)
return s},
aN(a){return this.aQ(0,!0)},
l(a){return A.oO(this,"{","}")},
gH(a){var s=this.gI(this)
if(!s.p())throw A.c(A.bZ())
return s.gF()},
$iH:1,
$ibJ:1}
A.fH.prototype={}
A.io.prototype={
R(a,b){return A.uB()}}
A.fm.prototype={
gt(a){return this.a.a},
gI(a){var s=this.a
return A.fz(s,s.r,A.E(s).c)}}
A.fO.prototype={}
A.ib.prototype={
h(a,b){var s,r=this.b
if(r==null)return this.c.h(0,b)
else if(typeof b!="string")return null
else{s=r[b]
return typeof s=="undefined"?this.ia(b):s}},
gt(a){return this.b==null?this.c.a:this.bw().length},
ga9(a){return this.gt(0)===0},
gaa(a){return this.gt(0)>0},
gZ(){if(this.b==null){var s=this.c
return new A.aB(s,A.E(s).i("aB<1>"))}return new A.ic(this)},
gaO(){var s,r=this
if(r.b==null){s=r.c
return new A.b0(s,A.E(s).i("b0<2>"))}return A.oX(r.bw(),new A.nH(r),t.N,t.z)},
k(a,b,c){var s,r,q=this
if(q.b==null)q.c.k(0,b,c)
else if(q.D(b)){s=q.b
s[b]=c
r=q.a
if(r==null?s!=null:r!==s)r[b]=null}else q.f3().k(0,b,c)},
D(a){if(this.b==null)return this.c.D(a)
if(typeof a!="string")return!1
return Object.prototype.hasOwnProperty.call(this.a,a)},
J(a,b){var s
if(this.D(a))return this.h(0,a)
s=b.$0()
this.k(0,a,s)
return s},
T(a,b){if(this.b!=null&&!this.D(b))return null
return this.f3().T(0,b)},
a1(a,b){var s,r,q,p,o=this
if(o.b==null)return o.c.a1(0,b)
s=o.bw()
for(r=0;r<s.length;++r){q=s[r]
p=o.b[q]
if(typeof p=="undefined"){p=A.o1(o.a[q])
o.b[q]=p}b.$2(q,p)
if(s!==o.c)throw A.c(A.aA(o))}},
bw(){var s=this.c
if(s==null)s=this.c=A.a(Object.keys(this.a),t.s)
return s},
f3(){var s,r,q,p,o,n=this
if(n.b==null)return n.c
s=A.o(t.N,t.z)
r=n.bw()
for(q=0;p=r.length,q<p;++q){o=r[q]
s.k(0,o,n.h(0,o))}if(p===0)r.push("")
else B.b.v(r)
n.a=n.b=null
return n.c=s},
ia(a){var s
if(!Object.prototype.hasOwnProperty.call(this.a,a))return null
s=A.o1(this.a[a])
return this.b[a]=s}}
A.nH.prototype={
$1(a){return this.a.h(0,a)},
$S:36}
A.ic.prototype={
gt(a){return this.a.gt(0)},
an(a,b){var s=this.a
return s.b==null?s.gZ().an(0,b):s.bw()[b]},
gI(a){var s=this.a
if(s.b==null){s=s.gZ()
s=s.gI(s)}else{s=s.bw()
s=new J.bd(s,s.length,A.z(s).i("bd<1>"))}return s},
E(a,b){return this.a.D(b)}}
A.nX.prototype={
$0(){var s,r
try{s=new TextDecoder("utf-8",{fatal:true})
return s}catch(r){}return null},
$S:34}
A.nW.prototype={
$0(){var s,r
try{s=new TextDecoder("utf-8",{fatal:false})
return s}catch(r){}return null},
$S:34}
A.h3.prototype={}
A.h6.prototype={}
A.j3.prototype={}
A.eF.prototype={
l(a){var s=A.hc(this.a)
return(this.b!=null?"Converting object to an encodable object failed:":"Converting object did not return an encodable object:")+" "+s}}
A.ht.prototype={
l(a){return"Cyclic error in JSON stringify"}}
A.lN.prototype={
ag(a){var s=A.vl(a,this.giC().a)
return s},
dz(a,b){var s=A.uc(a,this.giD().b,null)
return s},
bC(a){return this.dz(a,null)},
giD(){return B.cG},
giC(){return B.cF}}
A.lP.prototype={}
A.lO.prototype={}
A.nJ.prototype={
fE(a){var s,r,q,p,o,n,m=a.length
for(s=this.c,r=0,q=0;q<m;++q){p=a.charCodeAt(q)
if(p>92){if(p>=55296){o=p&64512
if(o===55296){n=q+1
n=!(n<m&&(a.charCodeAt(n)&64512)===56320)}else n=!1
if(!n)if(o===56320){o=q-1
o=!(o>=0&&(a.charCodeAt(o)&64512)===55296)}else o=!1
else o=!0
if(o){if(q>r)s.a+=B.a.O(a,r,q)
r=q+1
o=A.at(92)
s.a+=o
o=A.at(117)
s.a+=o
o=A.at(100)
s.a+=o
o=p>>>8&15
o=A.at(o<10?48+o:87+o)
s.a+=o
o=p>>>4&15
o=A.at(o<10?48+o:87+o)
s.a+=o
o=p&15
o=A.at(o<10?48+o:87+o)
s.a+=o}}continue}if(p<32){if(q>r)s.a+=B.a.O(a,r,q)
r=q+1
o=A.at(92)
s.a+=o
switch(p){case 8:o=A.at(98)
s.a+=o
break
case 9:o=A.at(116)
s.a+=o
break
case 10:o=A.at(110)
s.a+=o
break
case 12:o=A.at(102)
s.a+=o
break
case 13:o=A.at(114)
s.a+=o
break
default:o=A.at(117)
s.a+=o
o=A.at(48)
s.a=(s.a+=o)+o
o=p>>>4&15
o=A.at(o<10?48+o:87+o)
s.a+=o
o=p&15
o=A.at(o<10?48+o:87+o)
s.a+=o
break}}else if(p===34||p===92){if(q>r)s.a+=B.a.O(a,r,q)
r=q+1
o=A.at(92)
s.a+=o
o=A.at(p)
s.a+=o}}if(r===0)s.a+=a
else if(r<m)s.a+=B.a.O(a,r,m)},
cV(a){var s,r,q,p
for(s=this.a,r=s.length,q=0;q<r;++q){p=s[q]
if(a==null?p==null:a===p)throw A.c(new A.ht(a,null))}s.push(a)},
cK(a){var s,r,q,p,o=this
if(o.fD(a))return
o.cV(a)
try{s=o.b.$1(a)
if(!o.fD(s)){q=A.q3(a,null,o.geK())
throw A.c(q)}o.a.pop()}catch(p){r=A.aU(p)
q=A.q3(a,r,o.geK())
throw A.c(q)}},
fD(a){var s,r,q=this
if(typeof a=="number"){if(!isFinite(a))return!1
q.c.a+=B.h.l(a)
return!0}else if(a===!0){q.c.a+="true"
return!0}else if(a===!1){q.c.a+="false"
return!0}else if(a==null){q.c.a+="null"
return!0}else if(typeof a=="string"){s=q.c
s.a+='"'
q.fE(a)
s.a+='"'
return!0}else if(t.j.b(a)){q.cV(a)
q.jh(a)
q.a.pop()
return!0}else if(t.f.b(a)){q.cV(a)
r=q.ji(a)
q.a.pop()
return r}else return!1},
jh(a){var s,r,q=this.c
q.a+="["
s=J.X(a)
if(s.gaa(a)){this.cK(s.h(a,0))
for(r=1;r<s.gt(a);++r){q.a+=","
this.cK(s.h(a,r))}}q.a+="]"},
ji(a){var s,r,q,p,o,n=this,m={}
if(a.ga9(a)){n.c.a+="{}"
return!0}s=a.gt(a)*2
r=A.a9(s,null,!1,t.X)
q=m.a=0
m.b=!0
a.a1(0,new A.nK(m,r))
if(!m.b)return!1
p=n.c
p.a+="{"
for(o='"';q<s;q+=2,o=',"'){p.a+=o
n.fE(A.is(r[q]))
p.a+='":'
n.cK(r[q+1])}p.a+="}"
return!0}}
A.nK.prototype={
$2(a,b){var s,r,q,p
if(typeof a!="string")this.a.b=!1
s=this.b
r=this.a
q=r.a
p=r.a=q+1
s[q]=a
r.a=p+1
s[p]=b},
$S:47}
A.nI.prototype={
geK(){var s=this.c.a
return s.charCodeAt(0)==0?s:s}}
A.nb.prototype={
ff(a,b){return(b===!0?B.d8:B.d7).aC(a)},
ag(a){return this.ff(a,null)}}
A.nc.prototype={
aC(a){var s,r,q=A.c4(0,null,a.length)
if(q===0)return new Uint8Array(0)
s=new Uint8Array(q*3)
r=new A.nY(s)
if(r.hJ(a,0,q)!==q)r.dq()
return B.j.bj(s,0,r.b)}}
A.nY.prototype={
dq(){var s=this,r=s.c,q=s.b,p=s.b=q+1
r.$flags&2&&A.i(r)
r[q]=239
q=s.b=p+1
r[p]=191
s.b=q+1
r[q]=189},
it(a,b){var s,r,q,p,o=this
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
return!0}else{o.dq()
return!1}},
hJ(a,b,c){var s,r,q,p,o,n,m,l,k=this
if(b!==c&&(a.charCodeAt(c-1)&64512)===55296)--c
for(s=k.c,r=s.$flags|0,q=s.length,p=b;p<c;++p){o=a.charCodeAt(p)
if(o<=127){n=k.b
if(n>=q)break
k.b=n+1
r&2&&A.i(s)
s[n]=o}else{n=o&64512
if(n===55296){if(k.b+4>q)break
m=p+1
if(k.it(o,a.charCodeAt(m)))p=m}else if(n===56320){if(k.b+3>q)break
k.dq()}else if(o<=2047){n=k.b
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
A.hX.prototype={
aC(a){return new A.d2(this.a).bK(a,0,null,!0)}}
A.d2.prototype={
bK(a,b,c,d){var s,r,q,p,o,n,m=this,l=A.c4(b,c,a.length)
if(b===l)return""
if(a instanceof Uint8Array){s=a
r=s
q=0}else{r=A.uD(a,b,l)
l-=b
q=b
b=0}if(l-b>=15){p=m.a
o=A.uC(p,r,b,l)
if(o!=null){if(!p)return o
if(o.indexOf("\ufffd")<0)return o}}o=m.cZ(r,b,l,!0)
p=m.b
if((p&1)!==0){n=A.uE(p)
m.b=0
throw A.c(A.cj(n,a,q+m.c))}return o},
cZ(a,b,c,d){var s,r,q=this
if(c-b>1000){s=B.c.a3(b+c,2)
r=q.cZ(a,b,s,!1)
if((q.b&1)!==0)return r
return r+q.cZ(a,s,c,d)}return q.iB(a,b,c,d)},
iB(a,b,c,d){var s,r,q,p,o,n,m,l=this,k=65533,j=l.b,i=l.c,h=new A.cr(""),g=b+1,f=a[b]
A:for(s=l.a;;){for(;;g=p){r="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAFFFFFFFFFFFFFFFFGGGGGGGGGGGGGGGGHHHHHHHHHHHHHHHHHHHHHHHHHHHIHHHJEEBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBKCCCCCCCCCCCCDCLONNNMEEEEEEEEEEE".charCodeAt(f)&31
i=j<=32?f&61694>>>r:(f&63|i<<6)>>>0
j=" \x000:XECCCCCN:lDb \x000:XECCCCCNvlDb \x000:XECCCCCN:lDb AAAAA\x00\x00\x00\x00\x00AAAAA00000AAAAA:::::AAAAAGG000AAAAA00KKKAAAAAG::::AAAAA:IIIIAAAAA000\x800AAAAA\x00\x00\x00\x00 AAAAA".charCodeAt(j+r)
if(j===0){q=A.at(i)
h.a+=q
if(g===c)break A
break}else if((j&1)!==0){if(s)switch(j){case 69:case 67:q=A.at(k)
h.a+=q
break
case 65:q=A.at(k)
h.a+=q;--g
break
default:q=A.at(k)
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
break}p=n}if(o-g<20)for(m=g;m<o;++m){q=A.at(a[m])
h.a+=q}else{q=A.tO(a,g,o)
h.a+=q}if(o===c)break A
g=p}else g=p}if(d&&j>32)if(s){s=A.at(k)
h.a+=s}else{l.b=77
l.c=c
return""}l.b=j
l.c=i
s=h.a
return s.charCodeAt(0)==0?s:s}}
A.aw.prototype={
dX(a){var s=1000,r=B.c.a7(a,s),q=B.c.a3(a-r,s),p=this.b+r,o=B.c.a7(p,s),n=this.c
return new A.aw(A.oE(this.a+B.c.a3(p-o,s)+q,o,n),o,n)},
aw(a,b){if(b==null)return!1
return b instanceof A.aw&&this.a===b.a&&this.b===b.b&&this.c===b.c},
gY(a){return A.q7(this.a,this.b,B.V,B.V)},
A(a,b){var s=B.c.A(this.a,b.a)
if(s!==0)return s
return B.c.A(this.b,b.b)},
l(a){var s=this,r=A.pO(A.b1(s)),q=A.bU(A.bB(s)),p=A.bU(A.bI(s)),o=A.bU(A.dN(s)),n=A.bU(A.eT(s)),m=A.bU(A.eU(s)),l=A.iW(A.qd(s)),k=s.b,j=k===0?"":A.iW(k)
k=r+"-"+q
if(s.c)return k+"-"+p+" "+o+":"+n+":"+m+"."+l+j+"Z"
else return k+"-"+p+" "+o+":"+n+":"+m+"."+l+j},
bs(){var s=this,r=A.b1(s)>=-9999&&A.b1(s)<=9999?A.pO(A.b1(s)):A.t1(A.b1(s)),q=A.bU(A.bB(s)),p=A.bU(A.bI(s)),o=A.bU(A.dN(s)),n=A.bU(A.eT(s)),m=A.bU(A.eU(s)),l=A.iW(A.qd(s)),k=s.b,j=k===0?"":A.iW(k)
k=r+"-"+q
if(s.c)return k+"-"+p+"T"+o+":"+n+":"+m+"."+l+j+"Z"
else return k+"-"+p+"T"+o+":"+n+":"+m+"."+l+j}}
A.iX.prototype={
$1(a){if(a==null)return 0
return A.d8(a)},
$S:58}
A.iY.prototype={
$1(a){var s,r,q
if(a==null)return 0
for(s=a.length,r=0,q=0;q<6;++q){r*=10
if(q<s)r+=a.charCodeAt(q)^48}return r},
$S:58}
A.bW.prototype={
aw(a,b){if(b==null)return!1
return b instanceof A.bW&&this.a===b.a},
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
return s+m+":"+q+r+":"+o+p+"."+B.a.a0(B.c.l(n%1e6),6,"0")}}
A.nq.prototype={
l(a){return this.c9()}}
A.ah.prototype={
gbI(){return A.tA(this)}}
A.h_.prototype={
l(a){var s=this.a
if(s!=null)return"Assertion failed: "+A.hc(s)
return"Assertion failed"}}
A.c7.prototype={}
A.bz.prototype={
gd0(){return"Invalid argument"+(!this.a?"(s)":"")},
gd_(){return""},
l(a){var s=this,r=s.c,q=r==null?"":" ("+r+")",p=s.d,o=p==null?"":": "+A.D(p),n=s.gd0()+q+o
if(!s.a)return n
return n+s.gd_()+": "+A.hc(s.gdD())},
gdD(){return this.b}}
A.dO.prototype={
gdD(){return this.b},
gd0(){return"RangeError"},
gd_(){var s,r=this.e,q=this.f
if(r==null)s=q!=null?": Not less than or equal to "+A.D(q):""
else if(q==null)s=": Not greater than or equal to "+A.D(r)
else if(q>r)s=": Not in inclusive range "+A.D(r)+".."+A.D(q)
else s=q<r?": Valid value range is empty":": Only valid value is "+A.D(r)
return s}}
A.hl.prototype={
gdD(){return this.b},
gd0(){return"RangeError"},
gd_(){if(this.b<0)return": index must not be negative"
var s=this.f
if(s===0)return": no indices are valid"
return": index should be less than "+s},
gt(a){return this.f}}
A.fn.prototype={
l(a){return"Unsupported operation: "+this.a}}
A.hT.prototype={
l(a){return"UnimplementedError: "+this.a}}
A.cq.prototype={
l(a){return"Bad state: "+this.a}}
A.h5.prototype={
l(a){var s=this.a
if(s==null)return"Concurrent modification during iteration."
return"Concurrent modification during iteration: "+A.hc(s)+"."}}
A.hA.prototype={
l(a){return"Out of Memory"},
gbI(){return null},
$iah:1}
A.ff.prototype={
l(a){return"Stack Overflow"},
gbI(){return null},
$iah:1}
A.nr.prototype={
l(a){return"Exception: "+this.a}}
A.hg.prototype={
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
bd(a,b,c){return A.oX(this,b,A.E(this).i("F.E"),c)},
E(a,b){var s
for(s=this.gI(this);s.p();)if(J.az(s.gF(),b))return!0
return!1},
j9(a,b){var s,r=this.gI(this)
if(!r.p())throw A.c(A.bZ())
s=r.gF()
while(r.p())s=b.$2(s,r.gF())
return s},
aQ(a,b){var s=A.r(this,A.E(this).i("F.E"))
return s},
aN(a){return this.aQ(0,!0)},
gt(a){var s,r=this.gI(this)
for(s=0;r.p();)++s
return s},
ga9(a){return!this.gI(this).p()},
gaa(a){return!this.ga9(this)},
gH(a){var s=this.gI(this)
if(!s.p())throw A.c(A.bZ())
return s.gF()},
an(a,b){var s,r
A.eX(b,"index")
s=this.gI(this)
for(r=b;s.p();){if(r===0)return s.gF();--r}throw A.c(A.oN(b,b-r,this,"index"))},
l(a){return A.tl(this,"(",")")}}
A.aj.prototype={
l(a){return"MapEntry("+A.D(this.a)+": "+A.D(this.b)+")"}}
A.aE.prototype={
gY(a){return A.A.prototype.gY.call(this,0)},
l(a){return"null"}}
A.A.prototype={$iA:1,
aw(a,b){return this===b},
gY(a){return A.hJ(this)},
l(a){return"Instance of '"+A.eV(this)+"'"},
gak(a){return A.fV(this)},
toString(){return this.l(this)}}
A.il.prototype={
l(a){return this.a},
$iaW:1}
A.bK.prototype={
gbB(){var s=this.gfg()
if($.cC()===1e6)return s
return s*1000},
gco(){var s=this.gfg()
if($.cC()===1000)return s
return B.c.a3(s,1000)},
b7(){var s=this,r=s.b
if(r!=null){s.a=s.a+($.bs.$0()-r)
s.b=null}},
gfg(){var s=this.b
if(s==null)s=$.bs.$0()
return s-this.a}}
A.cr.prototype={
gt(a){return this.a.length},
l(a){var s=this.a
return s.charCodeAt(0)==0?s:s},
gaa(a){return this.a.length!==0}}
A.lZ.prototype={
l(a){var s,r=this.a
if(r.length!==0){r="OS Error: "+r
s=this.b
if(s!==-1)r=r+", errno = "+B.c.l(s)}else{r=this.b
r=r!==-1?"OS Error: errno = "+B.c.l(r):"OS Error"}return r.charCodeAt(0)==0?r:r}}
A.fv.prototype={
gcC(){return this.a},
aU(){A.u1(A.bN(),this.b)},
dv(a){var s=this
if(s.aU())return
if(s.a!==A.dq(A.oH(s.gcC())).a)A.dq(A.oH(s.gcC())).dv(!0)
A.tZ(A.bN(),s.b)},
bx(a){A.u0(A.bN(),this.b,a)},
l(a){return"Directory: '"+this.a+"'"}}
A.cI.prototype={}
A.dt.prototype={
ci(a){var s,r=this,q=r.a
if(q.length!==0){q=a+(": "+q)+(", path = '"+r.b+"'")
s=r.c
if(s!=null)q+=" ("+s.l(0)+")"}else{q=r.c
if(q!=null)q=a+(": "+q.l(0))+(", path = '"+r.b+"'")
else q=a+(": "+r.b)}return q.charCodeAt(0)==0?q:q},
l(a){return this.ci("FileSystemException")}}
A.hF.prototype={
l(a){return this.ci("PathAccessException")}}
A.hG.prototype={
l(a){return this.ci("PathExistsException")}}
A.hH.prototype={
l(a){return this.ci("PathNotFoundException")}}
A.fw.prototype={
gcC(){return this.a},
aU(){A.u7(A.bN(),this.b)},
bx(a){var s,r
if(a){s=this.b
r=A.oG(s)
return new A.fv(B.a5.ff(B.j.gV(s)===0?J.bk(B.j.gai(s),s.byteOffset,s.length-1):s,!0),r).bx(!0)}A.u5(A.bN(),this.b)},
iW(a){return A.u6(12,[null,this.b]).jq(new A.ns(this),t.S)},
j1(a){if(a!==B.cx&&a!==B.cy&&a!==B.b8&&a!==B.cz&&a!==B.cA)throw A.c(A.bl("Invalid file mode for this operation",null))
A.u9(A.bN(),this.b,a.a)},
l(a){return"File: '"+this.a+"'"}}
A.ns.prototype={
$1(a){A.uT(a,"Cannot retrieve length of file",this.a.a)
return a},
$S:85}
A.ds.prototype={}
A.jh.prototype={
$2(a,b){this.a.cI(new A.jf(a),new A.jg(b),t.X)},
$S:86}
A.jf.prototype={
$1(a){var s=this.a
s.call(s,a)
return a},
$S:99}
A.jg.prototype={
$2(a,b){var s,r,q=t.g.a(v.G.Error),p=A.vX(q,["Dart exception thrown from converted Future. Use the properties 'error' to fetch the boxed error and 'stack' to recover the stack trace."])
if(t.aX.b(a))A.ap("Attempting to box non-Dart object.")
s={}
s[$.rC()]=a
p.error=s
p.stack=b.l(0)
r=this.a
r.call(r,p)
return p},
$S:101}
A.nF.prototype={
cA(a){if(a<=0||a>4294967296)throw A.c(A.qg(u.g+a))
return Math.random()*a>>>0},
fp(){return Math.random()}}
A.id.prototype={
dT(a){var s,r,q,p,o,n,m,l=this,k=4294967296
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
l.ba()
l.ba()
l.ba()
l.ba()},
ba(){var s=this,r=s.a,q=4294901760*r,p=q>>>0,o=55905*r,n=o>>>0,m=n+p+s.b
r=m>>>0
s.a=r
s.b=B.c.a3(o-n+(q-p)+(m-r),4294967296)>>>0},
cA(a){var s,r,q,p=this
if(a<=0||a>4294967296)throw A.c(A.qg(u.g+a))
s=a-1
if((a&s)>>>0===0){p.ba()
return(p.a&s)>>>0}do{p.ba()
r=p.a
q=r%a}while(r-q+a>=4294967296)
return q},
fp(){var s,r=this
r.ba()
s=r.a
r.ba()
return((s&67108863)*134217728+(r.a&134217727))/9007199254740992}}
A.j4.prototype={}
A.fY.prototype={}
A.fZ.prototype={
fe(a,b){var s=new Uint8Array(16)
new Uint8Array(16)
B.r.fO(A.aq(s,0,null),0,a)}}
A.j5.prototype={}
A.dI.prototype={}
A.ao.prototype={
aw(a,b){var s,r=this
if(b==null)return!1
if(r!==b)s=b instanceof A.ao&&A.fV(r)===A.fV(b)&&r.a===b.a&&r.b===b.b
else s=!0
return s},
gY(a){return B.a.gY(this.a)^B.c.gY(this.b)},
l(a){return"PageKey("+this.a+", "+this.b+")"}}
A.dJ.prototype={
cY(a,b){var s=this.e
if(s==null)return
new A.fZ(new A.fY(A.pH(s))).fe(a,b)},
bL(){var s,r,q=this,p=q.f
p===$&&A.b()
if(p)return
if(q.b==null)try{s=A.he(q.a)
if(!s.aU()){p=s
A.dq(A.oH(p.gcC())).dv(!0)
A.u4(A.bN(),p.b,!1)}q.b=s.j1(B.b8)}catch(r){q.b=null}},
a4(){var s=this,r=s.d
if(r!==-1)return r
r=s.f
r===$&&A.b()
if(r){r=s.r
return s.d=r.a===0?0:new A.aB(r,A.E(r).i("aB<1>")).j9(0,new A.mb())+1}s.bL()
r=s.b
if(r==null)return 0
r.iX()},
cF(a,b){var s,r,q=this,p=q.f
p===$&&A.b()
if(p){s=q.r.h(0,a)
if(s!=null)B.j.aj(b,0,s)
else B.j.bD(b,0,b.length,0)
return}q.bL()
p=q.b
if(p==null){B.j.bD(b,0,b.length,0)
return}r=q.d
if(a>=(r===-1?q.d=p.iX().aY(0,q.c):r)){q.d=a+1
B.j.bD(b,0,b.length,0)
return}p=q.b
p.dQ(a*q.c)
p.jp(b)
q.cY(a,b)},
cL(a,b){var s,r,q=this
if(a>=q.d)q.d=a+1
s=q.f
s===$&&A.b()
if(s){q.r.k(0,a,new Uint8Array(A.bx(b)))
return}q.bL()
s=q.b
if(s==null)return
s.dQ(a*q.c)
if(q.e!=null){r=new Uint8Array(A.bx(b))
q.cY(a,r)
q.b.cJ(r)}else s.cJ(b)},
jj(a,b){var s,r,q,p,o,n=this,m=b.length,l=n.c,k=B.c.aY(m,l),j=a+k
if(j>=n.d)n.d=j
s=n.f
s===$&&A.b()
if(s){for(s=n.r,r=0;r<k;r=p){q=r*l
p=r+1
s.k(0,a+r,new Uint8Array(b.subarray(q,A.pe(q,p*l,m))))}return}n.bL()
m=n.b
if(m==null)return
m.dQ(a*l)
if(n.e!=null){o=new Uint8Array(A.bx(b))
for(r=0;r<k;++r)n.cY(a+r,J.bk(B.j.gai(o),o.byteOffset+r*l,l))
n.b.cJ(o)}else m.cJ(b)},
bZ(){var s=this.f
s===$&&A.b()
if(s)return
s=this.b
if(s!=null)s.bZ()},
b2(){var s=this,r=s.f
r===$&&A.b()
if(r){s.r.v(0)
s.d=-1
return}r=s.b
if(r!=null){r.b2()
s.b=null}s.d=-1},
fC(a){var s,r,q=this
q.d=a
s=q.f
s===$&&A.b()
if(s){q.r.jb(0,new A.mc(a))
return}q.bL()
s=q.b
if(s==null)return
s.jm()
r=s.d.jr(0,a*q.c)
A.ap(A.pQ("truncate failed",s.a,r))}}
A.mb.prototype={
$2(a,b){return a>b?a:b},
$S:105}
A.mc.prototype={
$2(a,b){return a>=this.a},
$S:117}
A.hB.prototype={}
A.hO.prototype={}
A.n5.prototype={}
A.cS.prototype={}
A.m_.prototype={
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
e8(a,b){var s=this.f
if(s==null)return
new A.fZ(new A.fY(A.pH(s))).fe(a,b)},
hf(){if(this.gaI()!=null)return
return},
h1(a,b,c,d,e){var s,r,q,p,o,n=this
n.hf()
if(n.gaI()==null)return
s=new A.nm($.ou())
s.iu(a)
if(a===1){r=B.x.aC(B.o.bC(t.a.a(c)))
q=new DataView(new ArrayBuffer(4))
q.setUint32(0,r.length,!1)
s.R(0,J.ox(B.r.gai(q)))
s.R(0,r)}else if(a===2){p=n.w.J(d,new A.m0(d))
q=new DataView(new ArrayBuffer(8))
q.setUint32(0,p.length,!1)
q.setUint32(4,e,!1)
s.R(0,J.ox(B.r.gai(q)))
s.R(0,p)
s.R(0,t.p.a(c))
b.toString
s.R(0,b)}o=n.gaI()
o.toString
o.cJ(s.jc())},
bX(a,b){var s,r,q,p,o,n=this,m=n.gab()
if(m==null||n.c==null)return
s=m.c
if(s.E(0,a))return
r=m.b.h(0,a)
q=r==null?null:r.a
if(q==null)q=new Uint8Array(4096)
if(n.f!=null){p=new Uint8Array(A.bx(q))
o=new Uint8Array(A.bx(b))
r=a.b
n.e8(r,p)
n.e8(r,o)}else{o=b
p=q}n.h1(2,o,p,a.a,a.b)
s.R(0,a)},
j8(a){return},
c3(a){var s,r,q=this.ax,p=q.a++
q.b.k(0,p,B.au)
q=q.c
s=t.S
r=A.ts(q,s)
q.R(0,p)
this.sa5(new A.lU(p,r))
p=t.N
q=t.L
p=new A.n5(A.o(p,s),A.o(q,t.h0),A.aD(q),A.o(p,t.fi))
p.d=a.dO()
this.sab(p)},
ck(){var s,r,q,p=this
if(p.ga5()!=null){s=p.ax
r=p.ga5().a
s.b.k(0,r,B.U)
s.c.T(0,r)
p.sa5(null)}p.gab()!=null
p.sab(null)
p.bc()
s=p.gaI()
if(s!=null){try{p.gaI().bZ()
p.gaI().b2()}catch(q){}p.saI(null)}},
bF(a){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c=this
if(c.ga5()!=null){s=c.ax
r=c.ga5().a
s.b.k(0,r,B.b0)
s.c.T(0,r)
c.sa5(null)}q=c.gab()
if(q==null)return
for(s=q.b,s=new A.am(s,A.E(s).i("am<1,2>")).gI(0),r=c.d;s.p();){p=s.d
o=p.a
n=p.b.a
if(r.D(o)){m=r.h(0,o)
B.j.aj(m.b,0,n)
m.x=m.w=null
m.d=!0}else c.a_(o.a).cL(o.b,n)}for(s=q.a,s=new A.am(s,A.E(s).i("am<1,2>")).gI(0),n=A.E(r).i("aL<1>"),l=t.E;s.p();){p=s.d
k=p.a
j=p.b
i=c.a_(k)
if(c.bf(k)>j){h=A.a([],l)
for(g=new A.aL(r,r.r,r.e,n);g.p();){f=g.d
if(f.a===k&&f.b>=j)h.push(f)}for(g=h.length,e=0;e<h.length;h.length===g||(0,A.n)(h),++e)r.T(0,h[e])
i.fC(j)}}s=q.d
if(s!=null){a.dK(s)
a.aF()}c.bc()
c.sab(null)
if(c.gaI()!=null){try{c.gaI().b2()}catch(d){}c.saI(null)}},
fd(a,b){var s,r,q,p,o,n,m,l,k,j,i,h=this.gab()
if(h==null)throw A.c(A.q("No active transaction for savepoint."))
s=A.o(t.N,t.S)
r=A.o(t.L,t.p)
for(q=this.r,q=new A.an(q,q.r,q.e,A.E(q).i("an<2>")),p=this.d;q.p();){o=q.d
n=o.a4()
m=o.a
s.k(0,m,n)
for(l=0;l<n;++l){k=new A.ao(m,l)
if(p.D(k))r.k(0,k,new Uint8Array(A.bx(p.h(0,k).b)))
else{j=new Uint8Array(4096)
o.cF(l,j)
r.k(0,k,j)}}}for(q=h.a,q=new A.am(q,A.E(q).i("am<1,2>")).gI(0);q.p();){i=q.d
s.J(i.a,new A.m3(i))}h.e.k(0,a.toLowerCase(),new A.hO(a,b.dO(),s,r))},
fu(a,b){var s,r,q,p,o,n,m=this,l=m.gab()
if(l==null)throw A.c(A.q("No active transaction for savepoint."))
s=l.e
r=s.h(0,a.toLowerCase())
if(r==null)throw A.c(A.q("Savepoint '"+a+"' not found."))
r.d.a1(0,new A.m9(m))
r.c.a1(0,new A.ma(m))
b.dK(r.b)
b.aF()
q=A.E(s).i("aB<1>")
p=A.r(new A.aB(s,q),q.i("F.E"))
o=B.b.ad(p,a.toLowerCase())
if(o!==-1)for(n=o+1;n<p.length;++n)s.T(0,p[n])
m.bc()},
ja(a){var s,r,q,p,o,n=this.gab()
if(n==null)throw A.c(A.q("No active transaction for savepoint."))
s=n.e
if(!s.D(a.toLowerCase()))throw A.c(A.q("Savepoint '"+a+"' not found."))
r=A.E(s).i("aB<1>")
q=A.r(new A.aB(s,r),r.i("F.E"))
p=B.b.ad(q,a.toLowerCase())
if(p!==-1)for(o=p;o<q.length;++o)s.T(0,q[o])},
he(a){var s,r=this.gab()
if(r==null)return
s=r.a
if(!s.D(a))s.k(0,a,this.bf(a))},
iF(a){var s,r,q,p,o,n,m=A.a([],t.E)
for(r=this.d,q=new A.aL(r,r.r,r.e,A.E(r).i("aL<1>"));q.p();){p=q.d
if(p.a===a)m.push(p)}for(q=m.length,o=0;o<m.length;m.length===q||(0,A.n)(m),++o)r.T(0,m[o])
s=this.r.T(0,a)
if(s!=null)try{s.b2()}catch(n){}},
br(a,b){var s=this
if(s.gab()!=null){s.dc(new A.ao(a,b),s.C(a,b))
s.u(a,b,!1)}},
bf(a){var s,r,q,p=this.a_(a).a4()
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
o.he(s)
q=n.b
if(!q.D(a)){p=n.a
p.J(s,new A.m1(o,a))
s=p.h(0,s)
s.toString
if(a.b<s)q.k(0,a,new A.hB(new Uint8Array(A.bx(new Uint8Array(A.bx(b.b))))))}b.r=r},
a_(a){var s=this.r.J(a,new A.m7(this,a))
s.e=this.f
return s},
C(a,b){var s,r,q,p,o=this,n=new A.ao(a,b);++o.x
s=o.y
r=s.h(0,a)
s.k(0,a,b)
if(o.gab()==null&&r!=null&&b===r+1)o.ih(a,b+1)
s=o.d
if(s.D(n)){s=s.h(0,n)
s.toString
if(o.gab()!=null)o.dc(n,s);++s.e
o.e.T(0,n)
return s}q=o.a_(a)
p=A.q8(b,4096)
q.cF(b,p.b)
if(o.gab()!=null)o.dc(n,p)
if(s.a>=o.a)o.ed()
p.e=1
s.k(0,n,p)
return p},
ih(a,b){A.td(new A.m2(this,a,b),t.P)},
u(a,b,c){var s,r=new A.ao(a,b),q=this.d.h(0,r)
if(q==null)return
if(c)q.d=!0
s=q.e
if(s>0){--s
q.e=s
if(s===0)this.e.R(0,r)}},
iZ(a,b){var s=new A.ao(a,b),r=this.d.h(0,s)
if(r!=null&&r.d)this.bX(s,r.b)},
iY(){var s,r,q,p
for(s=this.d,s=new A.am(s,A.E(s).i("am<1,2>")).gI(0);s.p();){r=s.d
q=r.a
p=r.b
if(p.d)this.bX(q,p.b)}s=this.gaI()
if(s!=null)s.bZ()},
ed(){var s,r,q,p=this,o=p.e
if(o.a===0)return
s=o.gH(0)
o.T(0,s)
r=p.d.T(0,s)
if(r!=null&&r.d){q=p.r.h(0,s.a)
if(q!=null){o=r.b
p.bX(s,o)
q.cL(r.a,o)}}},
bc(){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3=this,a4=A.o(t.L,t.b7)
for(s=a3.d,s=new A.am(s,A.E(s).i("am<1,2>")).gI(0);s.p();){r=s.d
q=r.b
if(q.d)a4.k(0,r.a,q)}if(a4.a===0)return
s=a4.$ti.i("aB<1>")
p=A.r(new A.aB(a4,s),s.i("F.E"))
B.b.ar(p,new A.m5())
o=A.aD(t.d9)
n=A.o(t.N,t.be)
for(s=p.length,m=0;m<p.length;p.length===s||(0,A.n)(p),++m){l=p[m]
J.ae(n.J(l.a,new A.m6()),l)}for(s=new A.am(n,n.$ti.i("am<1,2>")).gI(0),q=a3.r;s.p();){r=s.d
k=r.a
j=r.b
i=q.h(0,k)
if(i==null)continue
o.R(0,i)
for(h=J.X(j),g=0;g<h.gt(j);g=e){f=g
for(;;){e=f+1
if(!(e<h.gt(j)&&h.h(j,e).b===h.h(j,f).b+1))break
f=e}if(f-g+1>1)for(d=g;d<=f;){c=d+255
c=c<f?c:f
b=c-d+1
a=b===256?$.pz():J.bk(B.j.gai($.pz()),0,b*4096)
for(a0=0;a0<b;++a0){l=h.h(j,d+a0)
a1=a4.h(0,l)
a2=a1.b
a3.bX(l,a2)
B.j.aj(a,a0*4096,a2)
a1.d=!1}i.jj(h.h(j,d).b,a)
d=c+1}else{l=h.h(j,g)
a1=a4.h(0,l)
a2=a1.b
a3.bX(l,a2)
i.cL(l.b,a2)
a1.d=!1}}}for(s=A.fz(o,o.r,o.$ti.c),q=s.$ti.c;s.p();){h=s.d;(h==null?q.a(h):h).bZ()}},
fi(a){var s,r,q,p,o,n,m,l=this
l.bc()
s=l.d
r=A.E(s).i("aB<1>")
q=r.i("aJ<F.E>")
p=A.r(new A.aJ(new A.aB(s,r),new A.m4(a),q),q.i("F.E"))
for(r=p.length,q=l.e,o=0;o<p.length;p.length===r||(0,A.n)(p),++o){n=p[o]
s.T(0,n)
q.T(0,n)}m=l.r.T(0,a)
if(m!=null)m.b2()},
du(){var s,r,q,p,o,n=this
n.z=!0
n.bc()
n.d.v(0)
n.e.v(0)
for(r=n.r,q=new A.an(r,r.r,r.e,A.E(r).i("an<2>"));q.p();)q.d.b2()
r.v(0)
for(r=n.Q,q=r.length,p=0;p<r.length;r.length===q||(0,A.n)(r),++p){s=r[p]
if(s.c!=null){try{s.c.b2()}catch(o){}s.c=null}}B.b.v(r)
r=n.as
q=r.c
if(q!=null){try{q.b2()}catch(o){}r.c=null}}}
A.m0.prototype={
$0(){return new Uint8Array(A.bx(B.x.aC(this.a)))},
$S:119}
A.m3.prototype={
$0(){return this.a.b},
$S:13}
A.m9.prototype={
$2(a,b){var s,r=this.a,q=r.d
if(q.D(a)){s=q.h(0,a)
B.j.aj(s.b,0,b)
s.x=s.w=null
s.d=!0}else r.a_(a.a).cL(a.b,b)},
$S:59}
A.ma.prototype={
$2(a,b){var s,r,q,p=this.a,o=p.a_(a)
if(o.a4()>b){s=A.a([],t.E)
p=p.d
p.a1(0,new A.m8(a,b,s))
for(r=s.length,q=0;q<s.length;s.length===r||(0,A.n)(s),++q)p.T(0,s[q])
o.fC(b)}},
$S:10}
A.m8.prototype={
$2(a,b){if(a.a===this.a&&a.b>=this.b)this.c.push(a)},
$S:122}
A.m1.prototype={
$0(){return this.a.bf(this.b.a)},
$S:13}
A.m7.prototype={
$0(){var s=this.b,r=new A.dJ(s,4096,A.o(t.S,t.p))
B.a.U(s,":memory:")
r.f=!0
return r},
$S:135}
A.m2.prototype={
$0(){var s,r,q,p,o,n,m,l,k
try{o=this.a
if(o.z)return
n=this.b
m=this.c
s=new A.ao(n,m)
l=o.d
if(l.D(s))return
r=o.a_(n)
q=r.a4()
if(m>=q)return
p=A.q8(m,4096)
r.cF(m,p.b)
if(o.z){r.b2()
return}if(!l.D(s)){if(l.a>=o.a)o.ed()
p.e=0
l.k(0,s,p)
o.e.R(0,s)}}catch(k){}},
$S:12}
A.m5.prototype={
$2(a,b){var s=B.a.A(a.a,b.a)
if(s!==0)return s
return B.c.A(a.b,b.b)},
$S:64}
A.m6.prototype={
$0(){return A.a([],t.E)},
$S:65}
A.m4.prototype={
$1(a){return a.a===this.a},
$S:66}
A.dV.prototype={
c9(){return"TxStatus."+this.b}}
A.lU.prototype={}
A.lV.prototype={
aD(a,b,c,d){var s,r
if(a!==0){s=this.b.h(0,a)
if(s==null)s=B.U
if(s===B.b0)return!1
if(s===B.au)if(a!==c)return!1
if(s===B.U)if(d.E(0,a))return!1}if(b===0)return!0
r=this.b.h(0,b)
if(r==null)r=B.U
if(r===B.b0)return!0
if(r===B.au)if(b===c)return!1
else return!0
if(r===B.U){if(d.E(0,b))return!0
return!1}return!0}}
A.cm.prototype={
al(){var s=this,r=s.d,q=new Uint8Array(12+r.length),p=A.aq(q,0,null)
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
s=B.b.S(s," | ")+"\n"+(B.a.P("-",s.length*12)+"\n")
for(r=o.length,q=t.N,p=0;p<o.length;o.length===r||(0,A.n)(o),++p)s+=B.b.bd(o[p],new A.mF(),q).S(0," | ")+"\n"
return s.charCodeAt(0)==0?s:s},
gfw(){return this.b}}
A.mF.prototype={
$1(a){return a.l(0)},
$S:18}
A.h8.prototype={
cB(a){var s=this.w
s.h(0,a.toLowerCase())
s.h(0,"*")},
fI(a){return this.x.h(0,a.toLowerCase())},
iA(a){this.y.J(a.toLowerCase(),new A.iV())},
bq(){var s=0,r=A.b5(t.H),q=this,p,o
var $async$bq=A.b6(function(a,b){if(a===1)return A.b2(b,r)
for(;;)switch(s){case 0:$.eB.v(0)
p=q.b
p===$&&A.b()
s=2
return A.as(p.dF(),$async$bq)
case 2:o=q.c
o===$&&A.b()
o.j8(p)
return A.b3(null,r)}})
return A.b4($async$bq,r)},
b6(a){var s,r,q,p,o,n,m=this,l=a.toLowerCase(),k=m.r
if(k.D(l)){k=k.h(0,l)
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
n=A.h1(s,m.a+"/"+p+".idx",q)
n.ap()
k.k(0,l,n)
k.k(0,p,n)
return n},
L(){var s=0,r=A.b5(t.H),q=this,p
var $async$L=A.b6(function(a,b){if(a===1)return A.b2(b,r)
for(;;)switch(s){case 0:q.r.v(0)
p=q.c
p===$&&A.b()
p.du()
return A.b3(null,r)}})
return A.b4($async$L,r)}}
A.iV.prototype={
$0(){return new A.fs(null,t.af)},
$S:70}
A.jO.prototype={
hS(a){var s=a.toLowerCase()
return this.ay.J(s,new A.kR(this,s))},
h2(a,b){var s,r=a.length
if(r!==b.length)return!1
for(s=0;s<r;++s)if(a[s]!==b[s])return!1
return!0},
cs(a){return this.iG(a)},
iG(a){var s=0,r=A.b5(t.V),q,p=this,o,n
var $async$cs=A.b6(function(b,c){if(b===1)return A.b2(c,r)
for(;;)switch(s){case 0:n=p.cy
n===$&&A.b()
o=t.X
q=A.wi(new A.kT(p,a),A.a7([B.F,n],o,o),t.aM)
s=1
break
case 1:return A.b3(q,r)}})
return A.b4($async$cs,r)},
aB(a5){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0=this,a1="' created successfully.",a2="' already exists.",a3="' does not exist.",a4="' does not exist in table '"
$.cN=a0
if(a5 instanceof A.f_)throw A.c(new A.dQ(a0.f.J(a5.a,new A.kp(a5)).$1(a0.c)))
if(a5 instanceof A.cf){s=a5.a
a0.a.x.k(0,s.toLowerCase(),a5)
return new A.B(A.a([],t.s),A.a([],t.F),"Macro '"+s+a1,B.f)}if(a5 instanceof A.ej){s=a5.a
a0.a.iA(s)
return new A.B(A.a([],t.s),A.a([],t.F),"Event stream '"+s+a1,B.f)}if(a5 instanceof A.eo){s=a5.b
r=A.z(s).i("h<1,k>")
q=A.r(new A.h(s,new A.kq(a0),r),r.i("u.E"))
s=a5.a
p=a0.a.y.h(0,s.toLowerCase())
if(p!=null&&(p.c&4)===0)p.R(0,q)
return new A.B(A.a([],t.s),A.a([],t.F),"Event emitted to stream '"+s+"' successfully.",B.f)}if(a5 instanceof A.cG){s=a5.a
o=s.toLowerCase()
r=a0.a.b
r===$&&A.b()
if(r.x.D(o.toLowerCase()))A.ap(A.q("Procedure '"+o+a2))
n=A.qf(s,a5.d)
r=a0.a.b
r===$&&A.b()
r.x.k(0,n.a.toLowerCase(),n)
r.aF()
return new A.B(A.a([],t.s),A.a([],t.F),"Procedure '"+s+a1,B.f)}if(a5 instanceof A.cF){s=a5.a
o=s.toLowerCase()
r=a0.a.b
r===$&&A.b()
if(r.y.D(o.toLowerCase()))A.ap(A.q("Function '"+o+a2))
n=A.pU(s,a5.e)
r=a0.a.b
r===$&&A.b()
r.y.k(0,n.a.toLowerCase(),n)
r.aF()
return new A.B(A.a([],t.s),A.a([],t.F),"Function '"+s+a1,B.f)}if(a5 instanceof A.ec)return a0.hj(a5)
if(a5 instanceof A.es){a0.aZ()
s=a0.a.d
s===$&&A.b()
m=s.aL(a5.a).a6()
return new A.B(A.a(["QUERY PLAN"],t.s),A.a([A.a([new A.m(m)],t.K)],t.F),"Explain plan generated successfully.",B.f)}if(a5 instanceof A.dc)return a0.hh(a5)
if(a5 instanceof A.dk)return a0.ho(a5)
if(a5 instanceof A.dg)return a0.hl(a5)
if(a5 instanceof A.bR)return a0.hg(a5)
if(a5 instanceof A.dh)return a0.d1(a5)
if(a5 instanceof A.fc)return a0.hB()
if(a5 instanceof A.fa)return a0.hA(a5)
if(a5 instanceof A.cL)return a0.eh(a5)
if(a5 instanceof A.dp)return a0.hq(a5)
if(a5 instanceof A.fo)return a0.hE(a5)
if(a5 instanceof A.aS)return a0.ei(a5)
if(a5 instanceof A.cW||a5 instanceof A.dy||a5 instanceof A.dr||a5 instanceof A.dm)return a0.hD(t.cf.a(a5))
if(a5 instanceof A.dL)return a0.hx(a5)
if(a5 instanceof A.e9)return a0.hi(a5)
if(a5 instanceof A.ez)return a0.hw(a5)
if(a5 instanceof A.fr)return a0.hG(a5)
if(a5 instanceof A.ew)return a0.hu(a5)
if(a5 instanceof A.cH)return a0.eg(a5)
if(a5 instanceof A.f9)return a0.eg(new A.cH(a0.bJ(a5.a)))
if(a5 instanceof A.fb){s=t.K
return new A.B(A.a(["schema_name"],t.s),A.a([A.a([new A.m("public")],s),A.a([new A.m("information_schema")],s)],t.F),"2 schemas found.",B.f)}if(a5 instanceof A.eS)return a0.hy(a5)
if(a5 instanceof A.fl)return a0.hC(a5)
if(a5 instanceof A.em)return a0.hs(a5)
if(a5 instanceof A.el)return a0.hr(a5)
if(a5 instanceof A.ek)return a0.hp(a5)
if(a5 instanceof A.ea){s=a0.a
r=s.c
r===$&&A.b()
s=s.b
s===$&&A.b()
r.c3(s)
return new A.B(A.a([],t.s),A.a([],t.F),"Transaction started.",B.f)}if(a5 instanceof A.ee){a0.aS()
a0.aZ()
s=a0.a.c
s===$&&A.b()
s.ck()
s=a0.a.c
s===$&&A.b()
s.bc()
return new A.B(A.a([],t.s),A.a([],t.F),"Transaction committed.",B.f)}if(a5 instanceof A.f3){B.b.v(a0.e)
a0.cd()
s=a0.a
r=s.c
r===$&&A.b()
s=s.b
s===$&&A.b()
r.bF(s)
a0.r.v(0)
return new A.B(A.a([],t.s),A.a([],t.F),"Transaction rolled back.",B.f)}if(a5 instanceof A.f6){a0.aS()
s=a0.a
r=s.c
r===$&&A.b()
l=a5.a
s=s.b
s===$&&A.b()
r.fd(l,s)
return new A.B(A.a([],t.s),A.a([],t.F),"Savepoint "+l+" created.",B.f)}if(a5 instanceof A.f2){B.b.v(a0.e)
a0.cd()
s=a0.a
r=s.c
r===$&&A.b()
l=a5.a
s=s.b
s===$&&A.b()
r.fu(l,s)
a0.r.v(0)
return new A.B(A.a([],t.s),A.a([],t.F),"Rolled back to savepoint "+l+".",B.f)}if(a5 instanceof A.eZ){s=a0.a.c
s===$&&A.b()
r=a5.a
s.ja(r)
return new A.B(A.a([],t.s),A.a([],t.F),"Savepoint "+r+" released.",B.f)}if(a5 instanceof A.dj){s=a5.a
k=s.toLowerCase()
r=a0.a.b
r===$&&A.b()
if(r.d.D(k.toLowerCase()))A.ap(A.q("Relationship '"+k+a2))
r=a0.a.b
r===$&&A.b()
l=a5.b
if(!r.c.D(l.toLowerCase()))A.ap(A.q("Source table '"+l+a3))
r=a0.a.b
r===$&&A.b()
j=a5.c
if(!r.c.D(j.toLowerCase()))A.ap(A.q("Destination table '"+j+a3))
r=a0.a.b
r===$&&A.b()
r=r.c.h(0,l.toLowerCase()).dx
r===$&&A.b()
i=a5.d
if(!B.b.E(r,i.toLowerCase()))A.ap(A.q("Key column '"+i+a4+l+"'."))
r=a0.a.b
r===$&&A.b()
r=r.c.h(0,j.toLowerCase()).dx
r===$&&A.b()
h=a5.e
if(!B.b.E(r,h.toLowerCase()))A.ap(A.q("Key column '"+h+a4+j+"'."))
r=a0.a.b
r===$&&A.b()
r.d.k(0,s.toLowerCase(),new A.dP(s,l,j,i,h))
return new A.B(A.a([],t.s),A.a([],t.F),"Relationship '"+s+a1,B.f)}if(a5 instanceof A.di)return a0.hn(a5)
if(a5 instanceof A.dl){s=a5.a
r=a5.d
g=A.qq(a5.c,a5.e,s,a5.w,r,a5.b)
l=a0.a.b
l===$&&A.b()
l.z.k(0,g.a.toLowerCase(),g)
l.aF()
return new A.B(A.a([],t.s),A.a([],t.F),"Trigger '"+s+"' created successfully on table '"+r+"'.",B.f)}if(a5 instanceof A.eQ){f=a5.a.toLowerCase()
e=a0.cx.h(0,f)
if(e==null)A.ap(A.q("Cursor '"+f+"' not declared."))
e.c=!0
s=a0.ei(e.b)
e.d=s
e.e=0
s=s.b.length!==0
e.f=s
r=a0.c
r.k(0,f+"%found",A.v(s?1:0))
r.k(0,f+"%notfound",A.v(e.f?0:1))
return new A.B(A.a([],t.s),A.a([],t.F),"Cursor '"+f+"' opened.",B.f)}if(a5 instanceof A.et)return a0.ht(a5)
if(a5 instanceof A.ed){f=a5.a.toLowerCase()
e=a0.cx.h(0,f)
if(e!=null){e.c=!1
e.d=null
e.e=0
s=a0.c
s.T(0,f+"%found")
s.T(0,f+"%notfound")}return new A.B(A.a([],t.s),A.a([],t.F),"Cursor '"+f+"' closed.",B.f)}if(a5 instanceof A.du)return a0.by()
if(a5 instanceof A.ey){s=a0.a.b
s===$&&A.b()
s.fJ(a5.c,a5.b,a5.a)
return new A.B(A.a([],t.s),A.a([],t.F),"Grant succeeded.",B.f)}if(a5 instanceof A.f1){s=a0.a.b
s===$&&A.b()
d=a5.c.toLowerCase()
c=a5.b.toLowerCase()
r=s.w
b=r.h(0,d)
if(b!=null){a=b.h(0,c)
if(a!=null){l=J.bb(a)
l.T(a,a5.a.toLowerCase())
if(l.ga9(a))b.T(0,c)
if(b.ga9(b))r.T(0,d)
s.aF()}}return new A.B(A.a([],t.s),A.a([],t.F),"Revoke succeeded.",B.f)}if(a5 instanceof A.f8){a0.b=a5.a
return new A.B(A.a([],t.s),A.a([],t.F),"User changed to "+a0.b+".",B.f)}if(a5 instanceof A.f7){s=a5.a
r=A.S(s.toLowerCase(),"'","")
o=B.a.W(A.S(r,'"',""))
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
return new A.B(r,l,"Engine option "+s+" set to "+j+".",B.f)}if(a5 instanceof A.ei)return a0.bM(a5)
if(a5 instanceof A.fp)return a0.bN(a5)
throw A.c(A.q("Unsupported AST Node type: "+A.fV(a5).l(0)))},
by(){var s=0,r=A.b5(t.V),q,p=this,o,n,m,l,k,j,i,h,g,f
var $async$by=A.b6(function(a,b){if(a===1)return A.b2(b,r)
for(;;)switch(s){case 0:s=3
return A.as(p.a.L(),$async$by)
case 3:if(A.dq(p.a.a).aU())for(n=A.a([],t.av),m=A.bN(),A.t6(void 1),A.u2(m,n,void 1,!1,!0),m=null.length,l=0;l<m;++l){o=null[l]
try{o.bx(!0)}catch(e){}}m=p.a.b
m===$&&A.b()
j=t.z
i=t.N
m.dK(A.a7(["tables",A.o(j,j),"relationships",A.o(j,j)],i,j))
s=4
return A.as(p.a.bq(),$async$by)
case 4:j=p.d
h=A.a6(j,!0,i)
B.b.v(j)
s=5
return A.as(p.cs("CREATE TABLE depts (id INT, name TEXT);\nINSERT INTO depts VALUES (1, 'Engineering');\nINSERT INTO depts VALUES (2, 'Marketing');\n\nCREATE TABLE employees (id INT, name TEXT, dept_id INT);\nINSERT INTO employees VALUES (101, 'Alice', 1);\nINSERT INTO employees VALUES (102, 'Bob', 1);\nINSERT INTO employees VALUES (103, 'Charlie', 2);\n\nCREATE TABLE customers (id INT, info JSON);\nINSERT INTO customers VALUES (1, '{\"name\": \"Alice\", \"age\": 28, \"address\": {\"city\": \"New York\"}}');\nINSERT INTO customers VALUES (2, '{\"name\": \"Bob\", \"age\": 22, \"address\": {\"city\": \"Boston\"}}');\nINSERT INTO customers VALUES (3, '{\"name\": \"Charlie\", \"age\": 35, \"address\": {\"city\": \"Chicago\"}}');\n\nCREATE TABLE products (id INT, name TEXT, embedding VECTOR);\nINSERT INTO products VALUES (1, 'Tech Running Shoes', '[0.1, 0.85, -0.2]');\nINSERT INTO products VALUES (2, 'Quantum Physics Book', '[0.9, 0.1, 0.1]');\nINSERT INTO products VALUES (3, 'Classic Cotton T-Shirt', '[0.15, 0.7, -0.1]');\n\nCREATE RELATIONSHIP works_in FROM employees TO depts ON dept_id = id;\n\nDECLARE\n  counter INT := 0;\n  total INT := 0;\nBEGIN\n  DBMS_OUTPUT.PUT_LINE('Generating sample data successfully.');\n  WHILE counter < 10 LOOP\n    counter := counter + 1;\n    total := total + counter;\n    IF counter % 2 = 0 THEN\n      DBMS_OUTPUT.PUT_LINE('Counter ' || counter || ' is EVEN');\n    ELSE\n      DBMS_OUTPUT.PUT_LINE('Counter ' || counter || ' is ODD');\n    END IF;\n  END LOOP;\n  DBMS_OUTPUT.PUT_LINE('PL/SQL Cumulative Total: ' || total);\nEND;\n"),$async$by)
case 5:g=b
m=j.length
if(m!==0)for(l=0,i="=== GENERATION SUCCESSFUL ===\n1. Relational Tables created (depts, employees).\n2. NoSQL Table created (customers with info JSON).\n3. AI Vector Table created (products with embeddings).\n4. Graph Relationship created (works_in).\n5. PL/SQL logic executed.\n\nPL/SQL Output:\n";l<m;++l)i+="  "+j[l]+"\n"
else i="=== GENERATION SUCCESSFUL ===\n1. Relational Tables created (depts, employees).\n2. NoSQL Table created (customers with info JSON).\n3. AI Vector Table created (products with embeddings).\n4. Graph Relationship created (works_in).\n5. PL/SQL logic executed.\n"
j.$flags&1&&A.i(j,"insertAll",2)
A.tG(0,0,m,"index")
f=h.length
j.length=m+f
B.b.aG(j,f,j.length,j,0)
B.b.a8(j,0,f,h)
q=new A.B(A.a(["status"],t.s),A.a([A.a([new A.m("SUCCESS")],t.K)],t.F),i.charCodeAt(0)==0?i:i,g.d)
s=1
break
case 1:return A.b3(q,r)}})
return A.b4($async$by,r)},
hj(a){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e=this,d=e.a.b
d===$&&A.b()
n=a.a
s=d.x.h(0,n.toLowerCase())
if(s==null)throw A.c(A.q("Procedure '"+n+"' does not exist."))
d=a.b
m=A.z(d).i("h<1,k>")
l=A.r(new A.h(d,new A.jT(e),m),m.i("u.E"))
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
o=e.aB(p)
if(o instanceof A.ad){m=A.q("Asynchronous operations are not supported inside procedures.")
throw A.c(m)}if(o instanceof A.B)q=o}}catch(f){if(!(A.aU(f) instanceof A.dQ))throw f}finally{d.v(0)
d.X(0,r)}d=q
d=d==null?null:d.a
if(d==null)d=A.a([],t.s)
m=q
m=m==null?null:m.b
if(m==null)m=A.a([],t.F)
return new A.B(d,m,"Procedure '"+n+"' executed successfully.",B.f)},
ho(a7){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1=this,a2=null,a3="' already exists.",a4=a7.a,a5=a4.toLowerCase(),a6=a1.a.b
a6===$&&A.b()
if(a6.c.D(a5.toLowerCase())){if(a7.e)return new A.B(A.a([],t.s),A.a([],t.F),"Table '"+a4+a3,B.f)
throw A.c(A.q("Table '"+a5+a3))}a6=a7.d
s=a6==null
if((s?a2:a6.a)!=null&&a7.b.length===0){r=a1.a.b
r===$&&A.b()
q=r.c.h(0,a6.a.toLowerCase().toLowerCase())
if(q!=null)for(r=q.b,p=a7.b,o=q.c,n=0;n<r.length;++n)p.push(new A.aZ(r[n],o[n],!1,!1,a2,a2,!1,a2,a2,a2))}r=a7.b
m=B.b.b1(r,new A.jY())
p=A.z(r)
o=p.i("h<1,e>")
o=A.r(new A.h(r,new A.jZ(),o),o.i("u.E"))
l=p.i("h<1,av>")
l=A.r(new A.h(r,new A.k_(),l),l.i("u.E"))
k=p.i("h<1,Q>")
j=k.i("u.E")
i=A.r(new A.h(r,new A.k0(),k),j)
h=A.r(new A.h(r,new A.k1(),k),j)
p=p.i("h<1,e?>")
g=p.i("u.E")
f=A.r(new A.h(r,new A.k2(),p),g)
e=A.r(new A.h(r,new A.k3(),p),g)
k=A.r(new A.h(r,new A.k4(),k),j)
p=A.r(new A.h(r,new A.k5(),p),g)
j=a7.c
j=j==null?a2:j.b
g=s?a2:a6.a
d=s?a2:a6.b
c=A.bL(a2,a2,p,o,k,i,e,f,l,h,a2,a2,m,!1,a4,j,a2,d,g,s?a2:a6.c,a2)
a6=c.CW
if(a6!=null){s=a1.a.b
s===$&&A.b()
q=s.c.h(0,a6.toLowerCase().toLowerCase())
if(q==null)throw A.c(A.q("Parent table '"+a6+"' does not exist."))
q.db.push(a4)
a6=a1.a.b
a6===$&&A.b()
a6.bo(q,!1)}a6=a1.a.b
a6===$&&A.b()
a6.bo(c,!0)
for(a6=r.length,s="idx_"+a5,p=s+"_",b=0;o=r.length,b<o;r.length===a6||(0,A.n)(r),++b){a=r[b]
if(a.c){o=a.a
a0=p+o.toLowerCase()
l=a1.a.b
l===$&&A.b()
if(!l.e.D(a0.toLowerCase())){l=a1.a.b
l===$&&A.b()
l.e.k(0,a0.toLowerCase(),new A.b8(a0,a4,o,a2))
l.r.v(0)
l.aF()}}}for(b=0;a6=r.length,b<a6;r.length===o||(0,A.n)(r),++b){a=r[b]
if(a.c||a.d){a6=a.a
a0=p+a6.toLowerCase()
l=a1.a.b
l===$&&A.b()
if(!l.e.D(a0.toLowerCase())){l=a1.a.b
l===$&&A.b()
l.e.k(0,a0.toLowerCase(),new A.b8(a0,a4,a6,a2))
l.r.v(0)
a1.a.b6(a0)}}}if(a6!==0&&r[0].a.toLowerCase()==="id"){a0=s+"_id"
a6=a1.a.b
a6===$&&A.b()
if(!a6.e.D(a0.toLowerCase())){a6=a1.a.b
a6===$&&A.b()
a6.f4(new A.b8(a0,a4,r[0].a,a2),!1)
a1.a.b6(a0)}}a6=A.a([],t.s)
s=A.a([],t.F)
r=m?" (optimized Columnar store)":" (Row store)"
return new A.B(a6,s,"Table '"+a4+"' created successfully"+r+".",B.f)},
hl(a){var s,r,q,p=null,o=a.a,n=o.toLowerCase(),m=this.a.b
m===$&&A.b()
if(m.c.D(n.toLowerCase()))throw A.c(A.q("Table '"+n+"' already exists."))
m=a.b
s=A.z(m)
r=s.i("h<1,e>")
r=A.r(new A.h(m,new A.jU(),r),r.i("u.E"))
s=s.i("h<1,av>")
m=A.r(new A.h(m,new A.jV(),s),s.i("u.E"))
q=A.bL(p,p,p,r,p,p,p,p,m,p,a.d,a.c,!1,!0,o,p,p,p,p,p,p)
m=this.a.b
m===$&&A.b()
m.bo(q,!0)
return new A.B(A.a([],t.s),A.a([],t.F),"Foreign table '"+o+"' created successfully.",B.f)},
hg(e2){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2,b3,b4,b5,b6,b7,b8,b9,c0,c1,c2,c3,c4,c5,c6,c7,c8,c9,d0,d1,d2,d3,d4,d5,d6,d7=this,d8=null,d9="' not found in table '",e0=e2.a.toLowerCase(),e1=d7.a.b
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
a5=A.bL(a2,a3,a,g,d,c,a1,a0,f,b,d8,d8,e,!1,i,d8,d8,d8,d8,d8,a4)
e1=d7.a.b
e1===$&&A.b()
e1.bo(a5,!1)
d7.ay.v(0)
d7.Q.v(0)
d7.as.v(0)
d7.CW.v(0)
d7.r.T(0,e0)
return new A.B(A.a([],t.s),A.a([],t.F),"Column '"+h+"' added to table '"+e0+"' successfully.",B.f)}else if(e1===B.b3){e1=e2.d
e1.toString
i=j.dx
i===$&&A.b()
s=B.b.ad(i,e1.toLowerCase())
if(J.az(s,-1))throw A.c(A.q("Column '"+e1+d9+e0+"'."))
h=j.e
if(h[s])throw A.c(A.q("Cannot drop primary key column '"+e1+"'."))
g=d7.a.b
g===$&&A.b()
a6=g.b5(e0,e1)
if(a6!=null){g=d7.a.b
g===$&&A.b()
f=a6.a
g.e.T(0,f.toLowerCase())
g.r.v(0)
r=A.he(d7.a.a+"/"+f.toLowerCase()+".idx")
if(r.aU())try{r.bx(!1)}catch(a7){}}g=j.d
if(g){a8=j.b.length
for(a9=s,f=j.a;a9<a8;++a9){e=d7.a
d=e.c
d===$&&A.b()
d.fi(e.a+"/"+f+".col_"+a9)}b0=A.he(d7.a.a+"/"+f+".col_"+A.D(s))
if(b0.aU())b0.bx(!1)
for(a9=s+1;a9<a8;++a9){b1=A.he(d7.a.a+"/"+f+".col_"+A.D(a9))
if(b1.aU()){e=d7.a
A.ua(A.bN(),b1.b,e.a+"/"+f+".col_"+A.D(a9-1))}}}else{f=d7.a
e=f.c
e===$&&A.b()
d=j.a
b2=A.aR(e,f.a,d)
f=d7.a.c
f===$&&A.b()
e=b2.c+"/"+b2.b+".db"
b3=f.a_(e).a4()
q=A.a([],t.aj)
for(b4=0;b4<b3;++b4){f=d7.a.c
f===$&&A.b()
b5=f.C(e,b4)
b6=b5.w
if(b6==null){f=b5.c
f===$&&A.b()
b6=b5.w=f.getUint16(1,!1)}for(b7=0;b7<b6;++b7){p=A.ab(b5,b7)
if(p!=null)try{o=A.aV(p)
n=A.a4(o.d,d8,d8)
if(s<J.O(n))J.pF(n,s)
m=A.p0(n)
J.ae(q,new A.cm(o.a,o.b,o.c,m))}catch(a7){l=A.a4(p,d8,d8)
if(s<J.O(l))J.pF(l,s)
k=A.p0(l)
J.ae(q,new A.cm(0,0,0,k))}}f=d7.a.c
f===$&&A.b()
f.u(e,b4,!1)}f=d7.a.c
f===$&&A.b()
f.fi(e)
b8=A.he(e)
if(b8.aU())b8.bx(!1)
f=d7.a
e=f.c
e===$&&A.b()
b9=A.aR(e,f.a,d)
for(f=q,e=f.length,c0=0;c0<f.length;f.length===e||(0,A.n)(f),++c0)b9.iM(f[c0].al())
b9.bE()}c1=B.b.ad(i,e1.toLowerCase())
if(c1===-1)A.ap(A.q("Column '"+e1+d9+j.a+"'."))
c2=A.a6(j.b,!0,t.N)
B.b.aM(c2,c1)
c3=A.a6(j.c,!0,t.q)
B.b.aM(c3,c1)
i=t.y
c4=A.a6(h,!0,i)
B.b.aM(c4,c1)
c5=A.a6(j.f,!0,i)
B.b.aM(c5,c1)
h=t.T
c6=A.a6(j.r,!0,h)
B.b.aM(c6,c1)
c7=A.a6(j.w,!0,h)
B.b.aM(c7,c1)
c8=A.a6(j.x,!0,i)
B.b.aM(c8,c1)
i=t.O
c9=A.a6(j.y,!0,i)
B.b.aM(c9,c1)
d0=A.a6(j.z,!0,i)
B.b.aM(d0,c1)
a5=A.bL(d0,c9,d8,c2,c8,c4,c7,c6,c3,c5,d8,d8,g,!1,j.a,d8,d8,d8,d8,d8,j.Q)
g=d7.a.b
g===$&&A.b()
g.bo(a5,!1)
d7.ay.v(0)
d7.Q.v(0)
d7.as.v(0)
d7.CW.v(0)
d7.r.T(0,e0)
return new A.B(A.a([],t.s),A.a([],t.F),"Column '"+e1+"' dropped from table '"+e0+"' successfully.",B.f)}else if(e1===B.b4){e1=e2.e
e1.toString
i=e2.f
i.toString
h=j.dx
h===$&&A.b()
c1=B.b.ad(h,e1.toLowerCase())
if(c1===-1)A.ap(A.q("Column '"+e1+d9+j.a+"'."))
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
a5=A.bL(a1,a0,a3,c2,a,e,b,c,g,d,d2,d1,f,a4,h,d3,j.db,d5,d4,d6,a2)
a2=d7.a.b
a2===$&&A.b()
a2.bo(a5,!1)
d7.ay.v(0)
d7.Q.v(0)
d7.as.v(0)
d7.CW.v(0)
d7.r.T(0,e0)
return new A.B(A.a([],t.s),A.a([],t.F),"Column '"+e1+"' renamed to '"+i+"' successfully in table '"+e0+"'.",B.f)}else if(e1===B.b5){e1=e2.r
e1.toString
i=e2.w
i.toString
h=j.dx
h===$&&A.b()
c1=B.b.ad(h,e1.toLowerCase())
if(c1===-1)A.ap(A.q("Column '"+e1+d9+j.a+"'."))
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
a5=A.bL(a0,a,a2,h,b,f,c,d,c3,e,d1,a4,g,a3,i,d2,j.db,d4,d3,d5,a1)
a1=d7.a.b
a1===$&&A.b()
a1.bo(a5,!1)
d7.ay.v(0)
d7.Q.v(0)
d7.as.v(0)
d7.CW.v(0)
d7.r.T(0,e0)
return new A.B(A.a([],t.s),A.a([],t.F),"Column '"+e1+"' type altered successfully in table '"+e0+"'.",B.f)}else throw A.c(A.q("Unsupported ALTER TABLE action."))},
hn(a){var s,r,q=a.b,p=q.toLowerCase(),o=this.a.b
o===$&&A.b()
s=o.c.h(0,p.toLowerCase())
if(s==null)throw A.c(A.q("Table '"+p+"' does not exist."))
o=s.Q
if(B.b.b1(o,new A.jX(a)))throw A.c(A.q("Policy '"+a.a+"' already exists on table '"+q+"'."))
r=a.a
B.b.R(o,new A.br(r,a.c))
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
q=f.J(d,new A.kB(s))
r=q.$1(c)}c.k(0,s.a,r)}h=a.w
h===$&&A.b()
g=h.length
e=0
for(;e<h.length;h.length===g||(0,A.n)(h),++e){p=h[e]
this.aB(p)}for(o=0;o<k.length;++o){n=k[o]
m="new."+n.toLowerCase()
l="new."+A.D(n)
if(c.D(m)){h=o
g=c.h(0,m)
g.toString
a1[h]=g}else if(c.D(l)){h=o
g=c.h(0,l)
g.toString
a1[h]=g}}}finally{c.v(0)
c.X(0,b)}},
ht(a){var s,r,q,p,o=a.a.toLowerCase(),n=this.cx.h(0,o)
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
bM(a){return this.hk(a)},
hk(a){var s=0,r=A.b5(t.V),q,p,o,n,m
var $async$bM=A.b6(function(b,c){if(b===1)return A.b2(c,r)
for(;;)switch(s){case 0:o=a.a
n=o+"_db"
m=A.dq(n)
if(!m.aU())m.dv(!0)
p=A.oD(n,null)
s=3
return A.as(p.bq(),$async$bM)
case 3:s=4
return A.as(p.L(),$async$bM)
case 4:q=new A.B(A.a([],t.s),A.a([],t.F),"Database '"+o+"' created successfully.",B.f)
s=1
break
case 1:return A.b3(q,r)}})
return A.b4($async$bM,r)},
bN(a){return this.hF(a)},
hF(a){var s=0,r=A.b5(t.V),q,p=this,o,n,m,l,k
var $async$bN=A.b6(function(b,c){if(b===1)return A.b2(c,r)
for(;;)switch(s){case 0:l=a.a
k=l+"_db"
if(!A.dq(k).aU())throw A.c(A.q("Database '"+l+"' does not exist."))
s=3
return A.as(p.a.L(),$async$bN)
case 3:o=A.oD(k,null)
s=4
return A.as(o.bq(),$async$bN)
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
m=new A.cS()
n.Q.push(m)
p.cy=m
q=new A.B(A.a([],t.s),A.a([],t.F),"Switched to database '"+l+"'.",B.f)
s=1
break
case 1:return A.b3(q,r)}})
return A.b4($async$bN,r)},
h5(a,b,c){var s,r,q,p,o,n="Type mismatch for column '"
if(a instanceof A.d||a.gae()===b)return a
if(b===B.L&&a instanceof A.p)return new A.j(a.a)
if(b===B.M&&a instanceof A.m)try{s=B.o.ag(a.a)
return new A.L(s,null)}catch(r){s=A.q(n+c+"'. Expected "+b.l(0)+", found "+B.t.l(0)+".")
throw A.c(s)}if(b===B.W&&a instanceof A.m){q=A.vm(a.a)
if(q!=null)return q
throw A.c(A.q(n+c+"'. Expected "+b.l(0)+", found "+B.t.l(0)+"."))}if(b===B.a6){if(a instanceof A.p)return new A.aG(a.a!==0)
if(a instanceof A.m){s=a.a
return new A.aG(s.toLowerCase()==="true"||s==="1")}}if(b===B.a7&&a instanceof A.m)return new A.bn(a.a)
if(b===B.a8&&a instanceof A.m){p=A.bA(a.a)
if(p!=null)return new A.bm(p)}if(b===B.a9)if(a instanceof A.m)return new A.b_(new Uint8Array(A.bx(B.x.aC(a.a))))
if(b===B.aa){if(a instanceof A.p)return new A.a8(a.a)
if(a instanceof A.j)return new A.a8(a.a)
if(a instanceof A.m){o=A.aH(a.a)
if(o!=null)return new A.a8(o)}}throw A.c(A.q(n+c+"'. Expected "+b.l(0)+", found "+a.gae().l(0)+"."))},
eh(h9){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2,b3,b4,b5,b6,b7,b8,b9,c0,c1,c2,c3,c4,c5,c6,c7,c8,c9,d0,d1,d2,d3,d4,d5,d6,d7,d8,d9,e0,e1,e2,e3,e4,e5,e6,e7,e8,e9,f0,f1,f2,f3,f4,f5,f6,f7,f8,f9,g0,g1,g2,g3,g4,g5,g6,g7,g8,g9,h0,h1,h2=this,h3=null,h4="Unique constraint violation: value '",h5="' already exists in unique column '",h6="euclidean",h7={},h8=h9.c
if(h8!=null&&h8.length>1){for(a4=h8.length,a5=h9.a,a6=h9.d,a7=h9.e,a8=h9.f,a9=h9.r,b0=h9.w,b1=0,b2=0;b2<h8.length;h8.length===a4||(0,A.n)(h8),++b2){h2.eh(new A.cL(a5,h8[b2],h3,a6,a7,a8,a9,b0));++b1}return new A.B(A.a([],t.s),A.a([],t.F),""+b1+" rows inserted into table '"+a5+"'.",B.f)}h8=h2.a.b
h8===$&&A.b()
a4=h9.a
if(!h8.c_(h2.b,a4,"insert"))throw A.c(A.q("Permission denied: INSERT privilege required on table '"+a4+"' for user '"+h2.b+"'."))
b3=h7.a=h2.Q.J(h9,new A.kg(h2,h9))
b4=b3.a.toLowerCase()
h8=h9.b
a4=J.X(h8)
a5=a4.gt(h8)
a6=b3.b.length
if(a5!==a6)throw A.c(A.q("Column count mismatch. Expected "+a6+" values, found "+a4.gt(h8)+"."))
b5=a4.gt(h8)
b6=h2.ax
if(b6==null||b6.length!==b5)b6=h2.ax=A.a9(b5,new A.d(),!1,t.r)
a5=h2.at
if(a5.D(h9))b7=a5.h(0,h9)
else{b8=A.a([],t.t)
h8=a4.gI(h8)
for(;;){if(!h8.p()){b9=!0
break}a4=h8.gF()
if(a4 instanceof A.aQ)b8.push(a4.c)
else{b9=!1
break}}b7=b9?b8:h3
a5.k(0,h9,b7)}if(!(b7!=null)){c0=h2.as.J(h9,new A.kh(h9))
for(h8=J.X(c0),a4=h2.c,c1=0;c1<b5;++c1){c2=h8.h(c0,c1).$1(a4)
a5=h7.a
b6[c1]=h2.h5(c2,a5.c[c1],a5.b[c1])}}h8=h7.a
if(h8.db.length!==0&&h8.ch!=null){a4=h8.dx
a4===$&&A.b()
c3=B.b.ad(a4,h8.ch.toLowerCase())
if(c3===-1)throw A.c(A.q("Partition column "+A.D(h7.a.ch)+" not found in table "+b4+"."))
c2=b6[c3]
c4=c2.l(0)
if(c2 instanceof A.m)c4=c2.a
h8=h7.a.db
a4=h8.length
b2=0
for(;;){if(!(b2<h8.length)){c5=!1
break}c6=h8[b2]
a5=h2.a.b
a5===$&&A.b()
c7=a5.c.h(0,c6.toLowerCase().toLowerCase())
if(c7!=null&&c7.cx!=null&&c7.cy!=null){a5=c7.cx
a5.toString
if(c4===a5)a5=0
else a5=c4<a5?-1:1
if(a5>=0){a5=c7.cy
a5.toString
if(c4===a5)a5=0
else a5=c4<a5?-1:1
a5=a5<=0}else a5=!1
if(a5){h7.a=c7
b4=c7.a.toLowerCase()
c5=!0
break}}h8.length===a4||(0,A.n)(h8);++b2}if(!c5)throw A.c(A.q("No matching partition found for row in partitioned table '"+b4+"'. Partition value: '"+c4+"'"))}h8=h2.a.b
h8===$&&A.b()
c8=h8.cM(b4,"BEFORE","INSERT")
for(h8=c8.length,b2=0;b2<c8.length;c8.length===h8||(0,A.n)(c8),++b2)h2.d2(c8[b2],h7.a,b6)
h8=h7.a
a4=h8.fr
a4===$&&A.b()
if(a4){h2.aZ()
for(h8=h2.r,a4=t.n,c1=0;a5=h7.a,a6=a5.b,c1<a6.length;++c1){a7=a5.e[c1]
if(a7||a5.f[c1]){c2=b6[c1]
if(c2 instanceof A.d){if(a7)throw A.c(A.q("Primary key column '"+a6[c1]+"' cannot be NULL."))
continue}a5=h2.a.b
a5===$&&A.b()
c9=a5.b5(b4,a6[c1])
if(c9!=null)a5=c2 instanceof A.p||c2 instanceof A.j
else a5=!1
if(a5){if(c2 instanceof A.p)d0=c2.a
else d0=c2 instanceof A.j?c2.a:h3
d1=d0!=null
if(d1){s=h8.J(b4,new A.ki(h7,h2))
d2=h2.a.b6(c9.a).cQ(A.a([d0],a4),A.a([d0],a4))
r=!1
for(a5=d2.length,b2=0;b2<d2.length;d2.length===a5||(0,A.n)(d2),++b2){q=d2[b2]
a6=h2.a.c
a6===$&&A.b()
a7=s
p=A.ab(a6.C(a7.c+"/"+a7.b+".db",q.a),q.b)
if(p!=null)try{o=A.aV(p)
a6=h2.a.c
a6===$&&A.b()
n=a6.ga5()
a6=h2.a.c
a6===$&&A.b()
m=a6.ax
a6=n
d3=a6==null?h3:a6.a
l=d3==null?0:d3
a6=n
d4=a6==null?h3:a6.b
k=d4==null?B.u:d4
if(m.aD(o.a,o.b,l,k)){r=!0
a5=h2.a.c
a5===$&&A.b()
a6=s
a5.u(a6.c+"/"+a6.b+".db",q.a,!1)
break}}catch(d5){r=!0
a5=h2.a.c
a5===$&&A.b()
a6=s
a5.u(a6.c+"/"+a6.b+".db",q.a,!1)
break}a6=h2.a.c
a6===$&&A.b()
a7=s
a6.u(a7.c+"/"+a7.b+".db",q.a,!1)}if(r)throw A.c(A.q(h4+c2.l(0)+h5+h7.a.b[c1]+"'."))}}else d1=!1
if(!d1){d6=h8.J(b4,new A.kj(h7,h2))
a5=h2.a.c
a5===$&&A.b()
a6=d6.c+"/"+d6.b+".db"
d7=a5.a_(a6).a4()
for(d8=0;d8<d7;++d8){a5=h2.a.c
a5===$&&A.b()
d9=a5.C(a6,d8)
e0=d9.w
if(e0==null){a5=d9.c
a5===$&&A.b()
e0=d9.w=a5.getUint16(1,!1)}for(e1=0;e1<e0;++e1){j=A.ab(d9,e1)
if(j!=null){i=null
try{h=A.aV(j)
a5=h2.a.c
a5===$&&A.b()
g=a5.ga5()
a5=h2.a.c
a5===$&&A.b()
f=a5.ax
a5=g
d3=a5==null?h3:a5.a
e=d3==null?0:d3
a5=g
d4=a5==null?h3:a5.b
d=d4==null?B.u:d4
if(f.aD(h.a,h.b,e,d))i=A.a4(h.d,h3,h3)}catch(d5){i=A.a4(j,h3,h3)}if(i==null)continue
if(c1<J.O(i))if(J.a_(i,c1).A(0,c2)===0){h8=h2.a.c
h8===$&&A.b()
h8.u(a6,d8,!1)
throw A.c(A.q(h4+c2.l(0)+h5+h7.a.b[c1]+"'."))}}}a5=h2.a.c
a5===$&&A.b()
a5.u(a6,d8,!1)}}}}h8=a5}a4=h8.dy
a4===$&&A.b()
if(a4){for(h8=t.n,a4=h2.r,c1=0;a5=h7.a,c1<a5.b.length;++c1){e2=a5.r[c1]
e3=a5.w[c1]
if(e2!=null&&e3!=null){c2=b6[c1]
if(c2 instanceof A.d)continue
a5=h2.a.b
a5===$&&A.b()
e4=a5.c.h(0,e2.toLowerCase())
if(e4==null)throw A.c(A.q("Foreign key constraint error: referenced table '"+e2+"' does not exist."))
a5=e4.dx
a5===$&&A.b()
e5=B.b.ad(a5,e3.toLowerCase())
if(e5===-1)throw A.c(A.q("Foreign key constraint error: referenced column '"+e3+"' does not exist in table '"+e2+"'."))
a5=h2.a.b
a5===$&&A.b()
c9=a5.b5(e2,e3)
if(c9!=null)a5=c2 instanceof A.p||c2 instanceof A.j
else a5=!1
e6=!1
if(a5){if(c2 instanceof A.p)d0=c2.a
else d0=c2 instanceof A.j?c2.a:h3
if(d0!=null)e6=h2.a.b6(c9.a).bi(A.a([d0],h8))!=null}if(!e6){e7=a4.J(e2.toLowerCase(),new A.kk(h2,e4))
a5=h2.a.c
a5===$&&A.b()
a6=e7.c+"/"+e7.b+".db"
d7=a5.a_(a6).a4()
for(c5=!1,d8=0;d8<d7;++d8){a5=h2.a.c
a5===$&&A.b()
d9=a5.C(a6,d8)
e0=d9.w
if(e0==null){a5=d9.c
a5===$&&A.b()
e0=d9.w=a5.getUint16(1,!1)}for(e1=0;e1<e0;++e1){c=A.ab(d9,e1)
if(c!=null){b=null
try{a=A.aV(c)
a5=h2.a.c
a5===$&&A.b()
a0=a5.ga5()
a5=h2.a.c
a5===$&&A.b()
a1=a5.ax
a5=a0
l=a5==null?h3:a5.a
a2=l==null?0:l
a5=a0
k=a5==null?h3:a5.b
a3=k==null?B.u:k
if(a1.aD(a.a,a.b,a2,a3))b=A.a4(a.d,h3,h3)}catch(d5){b=A.a4(c,h3,h3)}if(b==null)continue
if(e5<J.O(b))if(J.a_(b,e5).A(0,c2)===0){c5=!0
break}}}a5=h2.a.c
a5===$&&A.b()
a5.u(a6,d8,!1)
if(c5)break}if(!c5)throw A.c(A.q("Foreign key constraint violation: value '"+c2.l(0)+"' in column '"+h7.a.b[c1]+"' does not exist in referenced column '"+e2+"("+e3+")'."))}}}h8=a5}if(h8.d){h2.w.J(b4,new A.kl(h7,h2)).iO(b6)
e8=0
e9=0}else{s=h2.r.J(b4,new A.km(h7,h2))
h8=h2.a.c
h8===$&&A.b()
h8=h8.ga5()
l=h8==null?h3:h8.a
f0=s.fo(b6,l==null?0:l)
e8=f0.a
e9=f0.b}h8=h2.a.b
h8===$&&A.b();++h8.aX(b4).a
h8=h2.a.b
h8===$&&A.b()
for(h8=J.au(h8.bu(b4)),a4=h2.z,a5=t.n,a6=h2.e,a7=b6.length,a8=t.G,a9=t.S,b0=t.gB,f1=t.D,f2=t.N,f3=t.eb;h8.p();){f4=h8.gF()
f5=a4.J(f4,new A.kn(f4))
f6=f4.c
f7=f6.split(",")
f8=A.a([],a5)
g0=f7.length
b2=0
for(;;){f9=!1
if(!(b2<f7.length)){f9=!0
break}g1=B.a.W(f7[b2])
g2=h7.a.dx
g2===$&&A.b()
g3=B.b.ad(g2,g1.toLowerCase())
if(g3===-1)break
g4=b6[g3]
if(g4 instanceof A.p)d0=g4.a
else if(g4 instanceof A.j)d0=g4.a
else if(g4 instanceof A.m){g1=g4.a
g5=A.aH(g1)
if(g5!=null)d0=g5
else{for(g2=g1.length,g6=0,g7=0;g7<g2;++g7)g6=B.c.a7(g6*31+g1.charCodeAt(g7),9007199254740991)
d0=g6}}else d0=h3
if(d0==null)break
f8.push(d0)
f7.length===g0||(0,A.n)(f7);++b2}g0=f4.d
if(g0==="fts"){g0=h7.a.dx
g0===$&&A.b()
g3=B.b.ad(g0,f6.toLowerCase())
if(g3!==-1&&g3<a7){c2=b6[g3]
if(c2 instanceof A.m){g8=new A.hh(h2.a.a+"/"+f4.a.toLowerCase()+".fts",A.o(f2,f3))
g8.ap()
g8.iv(c2.a,e8,e9)}}}else{g1=g0==null
if(g1)g2=h3
else g2=A.S(g0,"_","").toLowerCase()
if((g2==null?"":g2)!=="ivf"){if(g1)g1=h3
else g1=A.S(g0,"_","").toLowerCase()
g1=(g1==null?"":g1)==="ivfflat"}else g1=!0
if(g1){g0=h7.a.dx
g0===$&&A.b()
g3=B.b.ad(g0,f6.toLowerCase())
if(g3!==-1&&g3<a7){c2=b6[g3]
if(c2 instanceof A.a5){g9=new A.ho(h2.a.a+"/"+f4.a.toLowerCase()+".ivf_flat",!1,h6,A.a([],a8),A.o(a9,b0),A.a([],f1))
g9.ap()
g9.b4(c2,e8,e9)
g9.bg()}}}else if(g0==="hnsw"){g0=h7.a.dx
g0===$&&A.b()
g3=B.b.ad(g0,f6.toLowerCase())
if(g3!==-1&&g3<a7){c2=b6[g3]
if(c2 instanceof A.a5){h0=A.oL(!1,h2.a.a+"/"+f4.a.toLowerCase()+".hnsw",h6)
h0.ap()
h0.b4(c2,e8,e9)
h0.bg()}}}else if(f9&&f8.length===f7.length)a6.push(new A.bu(f5,b4,f6.toLowerCase(),f8,e8,e9))}}h8=h2.a.b
h8===$&&A.b()
h1=h8.cM(b4,"AFTER","INSERT")
for(h8=h1.length,b2=0;b2<h1.length;h1.length===h8||(0,A.n)(h1),++b2)h2.d2(h1[b2],h7.a,b6)
h2.a.cB(b4)
return new A.B(A.a([],t.s),A.a([],t.F),"1 row inserted successfully.",B.f)},
hq(e2){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2,b3,b4,b5,b6,b7,b8,b9,c0,c1,c2,c3,c4,c5,c6,c7,c8,c9,d0,d1,d2,d3,d4,d5,d6,d7,d8,d9=this,e0=null,e1=d9.a.b
e1===$&&A.b()
c7=e2.a
if(!e1.c_(d9.b,c7,"delete"))throw A.c(A.q("Permission denied: DELETE privilege required on table '"+c7+"' for user '"+d9.b+"'."))
d9.aZ()
s=c7.toLowerCase()
e1=d9.a.b
e1===$&&A.b()
r=e1.c.h(0,s.toLowerCase())
if(r==null)throw A.c(A.q("Table '"+A.D(s)+"' does not exist."))
if(r.d)throw A.c(A.q("Deletes are not supported on columnar tables."))
e1=d9.a.c
e1===$&&A.b()
q=e1.gab()!=null
if(!q){e1=d9.a
c7=e1.c
c7===$&&A.b()
e1=e1.b
e1===$&&A.b()
c7.c3(e1)}e1=d9.a.c
e1===$&&A.b()
e1=e1.ga5()
c8=e1==null?e0:e1.a
p=c8==null?0:c8
o=0
try{n=d9.r.J(s,new A.k7(d9,r))
e1=d9.a.c
e1===$&&A.b()
c7=n
m=e1.a_(c7.c+"/"+c7.b+".db")
l=m.a4()
k=A.a([],t.J)
c9=e2.b
j=c9
i=!1
if(j instanceof A.a0&&j.b==="="&&j.c instanceof A.I){h=t.w.a(j.c)
if(h.b.length===1||B.b.gH(h.b).toLowerCase()===s){g=B.b.gV(h.b).toLowerCase()
e1=d9.a.b
e1===$&&A.b()
f=e1.b5(s,g)
if(f!=null){e=d9.f.J(j.d,new A.k8(j))
d=e.$1(A.o(t.N,t.r))
if(d instanceof A.p)d0=d.a
else d0=d instanceof A.j?d.a:e0
c=d0
if(c!=null){b=d9.a.b6(f.a.toLowerCase())
a=b.bi(A.a([c],t.n))
if(a!=null){e1=d9.a.c
e1===$&&A.b()
c7=n
a0=e1.C(c7.c+"/"+c7.b+".db",a.a)
a1=A.ab(a0,a.b)
if(a1!=null){a2=null
try{a3=A.aV(a1)
e1=d9.a.c
e1===$&&A.b()
a4=e1.ga5()
e1=d9.a.c
e1===$&&A.b()
a5=e1.ax
e1=a4
d1=e1==null?e0:e1.b
a6=d1==null?B.u:d1
if(a5.aD(a3.a,a3.b,p,a6))a2=A.a4(a3.d,e0,e0)}catch(d2){a2=A.a4(a1,e0,e0)}if(a2!=null)J.ae(k,new A.cw(a.a,a.b,a2))}e1=d9.a.c
e1===$&&A.b()
c7=n
e1.u(c7.c+"/"+c7.b+".db",a.a,!1)}i=!0}}}}if(!i)for(a7=0,e1=c9!=null,c7=d9.CW,d3=d9.f;a7<l;++a7){d4=d9.a.c
d4===$&&A.b()
d5=n
a8=d4.C(d5.c+"/"+d5.b+".db",a7)
d5=a8
d6=d5.w
if(d6==null){d4=d5.c
d4===$&&A.b()
d6=d5.w=d4.getUint16(1,!1)}a9=d6
for(b0=0;b0<a9;++b0){b1=A.ab(a8,b0)
if(b1!=null){b2=null
try{b3=A.aV(b1)
d4=d9.a.c
d4===$&&A.b()
b4=d4.ga5()
d4=d9.a.c
d4===$&&A.b()
b5=d4.ax
d4=b4
a6=d4==null?e0:d4.b
b6=a6==null?B.u:a6
if(b5.aD(b3.a,b3.b,p,b6))b2=A.a4(b3.d,e0,e0)}catch(d2){b2=A.a4(b1,e0,e0)}if(b2!=null){b7=!0
if(e1){b8=c7.J(r.a.toLowerCase(),new A.k9(r))
b9=new A.aN(b2,b8)
c0=d3.J(c9,new A.ka(e2))
c1=c0.$1(b9)
if(!(c1 instanceof A.p&&c1.a===1))d7=c1 instanceof A.j&&c1.a>0
else d7=!0
b7=d7}if(b7)J.ae(k,new A.cw(a7,b0,b2))}}}d4=d9.a.c
d4===$&&A.b()
d5=n
d4.u(d5.c+"/"+d5.b+".db",a7,!1)}c2=d9.hS(r.a)
e1=d9.a.b
e1===$&&A.b()
c3=e1.aX(r.a)
c4=A.aD(t.N)
for(e1=k,c7=e1.length,d8=0;d8<e1.length;e1.length===c7||(0,A.n)(e1),++d8){c5=e1[d8]
n.dw(c5.a,c5.b,p);++o
d3=c3.a>0?c3.a-1:0
c3.a=d3
if(c2)for(c6=0;c6<r.b.length;++c6)d9.dZ(r.a,r.b[c6],c5.c[c6],p,c4)}if(!q){e1=d9.a.c
e1===$&&A.b()
e1.ck()}d9.a.cB(s)
e1=A.a([],t.s)
c7=A.a([],t.F)
d3=A.D(o)
return new A.B(e1,c7,d3+" rows deleted successfully.",B.f)}catch(d2){if(!q){e1=d9.a
c7=e1.c
c7===$&&A.b()
e1=e1.b
e1===$&&A.b()
c7.bF(e1)}throw d2}},
hE(h3){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2,b3,b4,b5,b6,b7,b8,b9,c0,c1,c2,c3,c4,c5,c6,c7,c8,c9,d0,d1,d2,d3,d4,d5,d6,d7,d8,d9,e0,e1,e2,e3,e4,e5,e6,e7,e8,e9,f0,f1,f2,f3,f4,f5,f6,f7,f8,f9,g0,g1,g2,g3,g4,g5,g6,g7,g8,g9,h0=this,h1=null,h2=h0.a.b
h2===$&&A.b()
f0=h3.a
if(!h2.c_(h0.b,f0,"update"))throw A.c(A.q("Permission denied: UPDATE privilege required on table '"+f0+"' for user '"+h0.b+"'."))
h0.aZ()
s=f0.toLowerCase()
h2=h0.a.b
h2===$&&A.b()
r=h2.c.h(0,s.toLowerCase())
if(r==null)throw A.c(A.q("Table '"+A.D(s)+"' does not exist."))
if(r.d)throw A.c(A.q("Updates are not supported on columnar tables."))
q=B.b.cu(r.b,new A.kC(h3))
if(J.az(q,-1))throw A.c(A.q("Column '"+h3.b+"' does not exist on table '"+A.D(s)+"'."))
h2=h0.a.c
h2===$&&A.b()
p=h2.gab()!=null
if(!p){h2=h0.a
f0=h2.c
f0===$&&A.b()
h2=h2.b
h2===$&&A.b()
f0.c3(h2)}h2=h0.a.c
h2===$&&A.b()
h2=h2.ga5()
f1=h2==null?h1:h2.a
o=f1==null?0:f1
n=0
try{m=h0.r.J(s,new A.kD(h0,r))
l=A.a([],t.J)
h2=h0.a.c
h2===$&&A.b()
f0=m
k=h2.a_(f0.c+"/"+f0.b+".db")
j=k.a4()
f2=h3.d
i=f2
h=null
if(i!=null){h2=h0.a.d
h2===$&&A.b()
h=h2.j4(s,i)}if(h!=null){g=h0.a.b6(h.a.a.toLowerCase())
f=g.cQ(h.b,h.c)
J.pG(f,new A.kE())
for(h2=f,f0=h2.length,f3=0;f3<h2.length;h2.length===f0||(0,A.n)(h2),++f3){e=h2[f3]
f4=h0.a.c
f4===$&&A.b()
f5=m
d=f4.C(f5.c+"/"+f5.b+".db",e.a)
c=A.ab(d,e.b)
if(c!=null){b=null
try{a=A.aV(c)
f4=h0.a.c
f4===$&&A.b()
a0=f4.ga5()
f4=h0.a.c
f4===$&&A.b()
a1=f4.ax
f4=a0
b2=f4==null?h1:f4.b
a2=b2==null?B.u:b2
if(a1.aD(a.a,a.b,o,a2))b=A.a4(a.d,h1,h1)}catch(f6){b=A.a4(c,h1,h1)}if(b!=null)J.ae(l,new A.cw(e.a,e.b,b))}f4=h0.a.c
f4===$&&A.b()
f5=m
f4.u(f5.c+"/"+f5.b+".db",e.a,!1)}}else for(a3=0,h2=f2!=null,f0=h0.CW,f4=h0.f;a3<j;++a3){f5=h0.a.c
f5===$&&A.b()
f7=m
a4=f5.C(f7.c+"/"+f7.b+".db",a3)
f7=a4
f8=f7.w
if(f8==null){f5=f7.c
f5===$&&A.b()
f8=f7.w=f5.getUint16(1,!1)}a5=f8
for(a6=0;a6<a5;++a6){a7=A.ab(a4,a6)
if(a7!=null){a8=null
try{a9=A.aV(a7)
f5=h0.a.c
f5===$&&A.b()
b0=f5.ga5()
f5=h0.a.c
f5===$&&A.b()
b1=f5.ax
f5=b0
a2=f5==null?h1:f5.b
b2=a2==null?B.u:a2
if(b1.aD(a9.a,a9.b,o,b2))a8=A.a4(a9.d,h1,h1)}catch(f6){a8=A.a4(a7,h1,h1)}if(a8!=null){b3=!0
if(h2){b4=f0.J(r.a.toLowerCase(),new A.kF(r))
b5=new A.aN(a8,b4)
b6=f4.J(f2,new A.kG(h3))
b7=b6.$1(b5)
if(!(b7 instanceof A.p&&b7.a===1))f9=b7 instanceof A.j&&b7.a>0
else f9=!0
b3=f9}if(b3)J.ae(l,new A.cw(a3,a6,a8))}}}f5=h0.a.c
f5===$&&A.b()
f7=m
f5.u(f7.c+"/"+f7.b+".db",a3,!1)}b8=h0.f.J(h3.c,new A.kH(h3))
b9=h0.CW.J(r.a.toLowerCase(),new A.kI(r))
for(h2=l,f0=h2.length,f4=t.n,f5=h0.z,f7=t.s,g0=t.e,g1=g0.i("u.E"),g2=h0.e,g3=t.r,f3=0;f3<h2.length;h2.length===f0||(0,A.n)(h2),++f3){c0=h2[f3]
c1=new A.aN(c0.c,b9)
c2=b8.$1(c1)
c3=r.c[q]
c4=c2
if(!(c4 instanceof A.d)&&c4.gae()!==c3)if(c3===B.L&&c4 instanceof A.p)c4=new A.j(c4.a)
else if(c3===B.M&&c4 instanceof A.m)try{c4=new A.L(B.o.ag(c4.a),h1)}catch(f6){}c5=A.a6(c0.c,!0,g3)
J.aX(c5,q,c4)
g4=h0.a.b
g4===$&&A.b()
c6=g4.cM(s,"BEFORE","UPDATE")
for(g4=c6,g5=g4.length,g6=0;g6<g4.length;g4.length===g5||(0,A.n)(g4),++g6){c7=g4[g6]
h0.d2(c7,r,c5)}c8=A.p0(c5)
c9=new A.cm(o,0,0,c8)
d0=c9.al()
g4=h0.a.c
g4===$&&A.b()
g5=m
d1=g4.C(g5.c+"/"+g5.b+".db",c0.a)
g5=d1.c
g5===$&&A.b()
d2=g5
d3=5+c0.b*4
d4=J.ix(d2,d3,!1)
d5=J.ix(d2,d3+2,!1)
if(J.O(d0)<=d5){B.j.aj(d1.b,d4,d0)
g4=d2
g5=J.O(d0)
g4.$flags&2&&A.i(g4,10)
J.iy(g4,d3+2,g5,!1)
g5=h0.a.c
g5===$&&A.b()
g4=m
g5.u(g4.c+"/"+g4.b+".db",c0.a,!0);++n}else{d6=J.ix(d2,3,!1)
d7=J.ix(d2,1,!1)
d8=5+d7*4
if(d6-d8>=J.O(d0)){d9=d6-J.O(d0)
B.j.aj(d1.b,d9,d0)
g4=d2
g4.$flags&2&&A.i(g4,10)
J.iy(g4,d3,d9,!1)
g4=d2
g5=J.O(d0)
g4.$flags&2&&A.i(g4,10)
J.iy(g4,d3+2,g5,!1)
g5=d2
g5.$flags&2&&A.i(g5,10)
J.iy(g5,3,d9,!1)
g5=h0.a.c
g5===$&&A.b()
g4=m
g5.u(g4.c+"/"+g4.b+".db",c0.a,!0);++n}else{g4=h0.a.c
g4===$&&A.b()
g5=m
g4.u(g5.c+"/"+g5.b+".db",c0.a,!1)
m.dw(c0.a,c0.b,o)
e0=m.fo(c5,o)
g5=h0.a.b
g5===$&&A.b()
e1=g5.bu(s)
for(g4=J.au(e1);g4.p();){e2=g4.gF()
e3=f5.J(e2,new A.kJ(e2))
g7=A.r(new A.h(A.a(e2.c.split(","),f7),new A.kK(),g0),g1)
e4=g7
e5=A.a([],f4)
for(g5=e4,g8=g5.length,g6=0;g6<g5.length;g5.length===g8||(0,A.n)(g5),++g6){e6=g5[g6]
e7=B.b.cu(r.b,new A.kL(e6))
if(!J.az(e7,-1)){e8=J.a_(c5,e7)
if(e8 instanceof A.p)g9=e8.a
else g9=e8 instanceof A.j?e8.a:0
e9=g9
J.ae(e5,e9)}}if(J.O(e5)!==0)g2.push(new A.bu(e3,s,e2.c,e5,e0.a,e0.b))}++n}}}if(!p){h2=h0.a.c
h2===$&&A.b()
h2.ck()}h0.a.cB(s)
h2=A.a([],f7)
f0=A.a([],t.F)
f4=A.D(n)
return new A.B(h2,f0,f4+" rows updated successfully.",B.f)}catch(f6){if(!p){h2=h0.a
f0=h2.c
f0===$&&A.b()
h2=h2.b
h2===$&&A.b()
f0.bF(h2)}throw f6}},
dZ(a,b,c,d,e){var s,r,q,p,o,n,m,l
if(e.E(0,a.toLowerCase()))return
e.R(0,a.toLowerCase())
s=this.a.b
s===$&&A.b()
s=s.c
s=new A.an(s,s.r,s.e,A.E(s).i("an<2>"))
while(s.p()){r=s.d
for(q=r.b,p=r.r,o=r.w,r=r.a,n=0;n<q.length;++n){m=p[n]
l=o[n]
if(m!=null&&l!=null)if(m.toLowerCase()===a.toLowerCase()&&l.toLowerCase()===b.toLowerCase())this.hc(r,q[n],c,d,e)}}e.T(0,a.toLowerCase())},
hc(a8,a9,b0,b1,b2){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5=this,a6=null,a7=a5.a.b
a7===$&&A.b()
m=a7.c.h(0,a8.toLowerCase().toLowerCase())
if(m==null)return
l=a5.r.J(a8.toLowerCase(),new A.jP(a5,m))
a7=a5.a.c
a7===$&&A.b()
k=l.c+"/"+l.b+".db"
j=a7.a_(k).a4()
a7=m.dx
a7===$&&A.b()
i=B.b.ad(a7,a9.toLowerCase())
if(i===-1)return
h=A.a([],t.J)
for(g=0;g<j;++g){a7=a5.a.c
a7===$&&A.b()
f=a7.C(k,g)
e=f.w
if(e==null){a7=f.c
a7===$&&A.b()
e=f.w=a7.getUint16(1,!1)}for(d=0;d<e;++d){s=A.ab(f,d)
if(s!=null){r=null
try{q=A.aV(s)
a7=a5.a.c
a7===$&&A.b()
p=a7.ga5()
a7=a5.a.c
a7===$&&A.b()
o=a7.ax
a7=p
c=a7==null?a6:a7.b
n=c==null?B.u:c
if(o.aD(q.a,q.b,b1,n))r=A.a4(q.d,a6,a6)}catch(b){r=A.a4(s,a6,a6)}if(r==null)continue
if(i<J.O(r))if(J.a_(r,i).A(0,b0)===0)h.push(new A.cw(g,d,r))}}a7=a5.a.c
a7===$&&A.b()
a7.u(k,g,!1)}for(a7=h.length,k=m.b,a=m.a,a0=0;a0<h.length;h.length===a7||(0,A.n)(h),++a0){a1=h[a0]
l.dw(a1.a,a1.b,b1)
a2=a5.a.b
a2===$&&A.b()
a3=a2.aX(a)
a2=a3.a
a3.a=a2>0?a2-1:0
for(a2=a1.c,a4=0;a4<k.length;++a4)a5.dZ(a,k[a4],a2[a4],b1,b2)}},
ei(c9){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2,b3,b4,b5,b6,b7,b8,b9,c0,c1,c2,c3,c4,c5=this,c6=null,c7="Permission denied: SELECT privilege required on table '",c8=c5.a.b
c8===$&&A.b()
l=c9.b
if(!c8.c_(c5.b,l,"select"))throw A.c(A.q(c7+l+"' for user '"+c5.b+"'."))
c8=c9.f
if((c8.length!==0?B.b.gH(c8):c6)!=null){k=c5.a.b
k===$&&A.b()
j=c5.b
if(!k.c_(j,(c8.length!==0?B.b.gH(c8):c6).a,"select"))throw A.c(A.q(c7+c9.giU(0).a+"' for user '"+c5.b+"'."))}c5.aZ()
i=l.toLowerCase()
if(i==="information_schema.tables"||i==="information.tables"){h=A.a(["table_catalog","table_schema","table_name","table_type","is_columnar"],t.s)
g=A.a([],t.F)
c8=c5.a.b
c8===$&&A.b()
c8.c.a1(0,new A.ku(g))
return new A.B(h,g,""+g.length+" tables found.",B.f)}if(i==="information_schema.columns"||i==="information.columns"){h=A.a(["table_catalog","table_schema","table_name","column_name","ordinal_position","data_type","is_nullable"],t.s)
g=A.a([],t.F)
c8=c5.a.b
c8===$&&A.b()
c8.c.a1(0,new A.kv(g))
return new A.B(h,g,""+g.length+" columns found.",B.f)}if(i==="information_schema.schemata"||i==="information.schemata")return new A.B(A.a(["catalog_name","schema_name","schema_owner"],t.s),A.a([A.a([new A.m("ultsql"),new A.m("public"),new A.m(c5.b)],t.K)],t.F),"1 schema found.",B.f)
l=c9.d
k=l==null
if((k?c6:l.b.toLowerCase())==="generate_series"||i==="generate_series"){f=k?c6:l.c
if(f==null)f=A.a([],t.U)
if(f.length!==0){e=A.K(f[0]).$1(A.o(t.N,t.r))
if(e instanceof A.p)d=e.a
else{d=A.a3(e.l(0),c6)
if(d==null)d=1}}else d=1
if(f.length>1){c=A.K(f[1]).$1(A.o(t.N,t.r))
if(c instanceof A.p)b=c.a
else{b=A.a3(c.l(0),c6)
if(b==null)b=10}}else b=10
if(f.length>2){a=A.K(f[2]).$1(A.o(t.N,t.r))
if(a instanceof A.p)a0=a.a
else{a0=A.a3(a.l(0),c6)
if(a0==null)a0=1}}else a0=1
g=A.a([],t.F)
if(a0>0)for(c8=t.K,a1=d;a1<=b;a1+=a0)g.push(A.a([A.v(a1)],c8))
else if(a0<0)for(c8=t.K,a1=d;a1>=b;a1+=a0)g.push(A.a([A.v(a1)],c8))
a2=c9.e
return new A.B(A.a([a2==null?"generate_series":a2],t.s),g,""+g.length+" rows generated.",B.f)}l=c5.a.b
l===$&&A.b()
a3=l.c.h(0,i.toLowerCase())
l=!1
if(a3!=null)if(!a3.d)if(c9.r!=null)c8=(c8.length!==0?B.b.gH(c8):c6)==null&&c9.as==null&&c9.w==null&&!A.v_(c9.a)
else c8=l
else c8=l
else c8=l
if(c8){a4=c9.r
if(a4 instanceof A.a0&&a4.b==="="&&a4.c instanceof A.I){c8=t.w.a(a4.c).b
if(c8.length===1||B.b.gH(c8).toLowerCase()===i){c8=B.b.gV(c8)
l=c5.a.b
l===$&&A.b()
a5=l.b5(i,c8.toLowerCase())
if(a5!=null){c8=a4.d
if(c8 instanceof A.ag){a6=c8.b
a7=typeof a6=="number"?a6:c6
if(a7!=null){c8=a5.a
a8=c5.a.b6(c8.toLowerCase()).bi(A.a([a7],t.n))
if(a8!=null){c8=c5.a
l=c8.c
l===$&&A.b()
k=a3.a
a9=A.aR(l,c8.a,k)
c8=c5.a.c
c8===$&&A.b()
l=a9.c+"/"+a9.b+".db"
j=a8.a
s=A.ab(c8.C(l,j),a8.b)
g=A.a([],t.F)
if(s!=null){r=null
try{q=A.aV(s)
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
if(o.aD(q.a,q.b,n,m))r=A.a4(q.d,c6,c6)}catch(b2){r=A.a4(s,c6,c6)}if(r!=null){b3=A.o(t.N,t.r)
for(c8=a3.b,k+=".",a1=0;a1<c8.length;++a1){b3.k(0,k+c8[a1],J.a_(r,a1))
b3.k(0,c8[a1],J.a_(r,a1))}b4=A.a([],t.K)
b5=A.a([],t.s)
b6=c9.a
if(b6.length===1){k=b6[0].a
k=k instanceof A.I&&B.b.gH(k.b)==="*"}else k=!1
if(k){k=A.z(c8).i("h<1,ai>")
b6=A.r(new A.h(c8,new A.kw(),k),k.i("u.E"))}for(c8=b6.length,b7=0;b7<b6.length;b6.length===c8||(0,A.n)(b6),++b7){b8=b6[b7]
k=b8.a
b9=A.bO(k,b3)
b4.push(b9)
c0=b8.b
if(c0==null)k=k instanceof A.I?B.b.S(k.b,"."):b9.l(0)
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
c1=c8.aL(c9)
if(new A.kz().$1(c1))return new A.kx(c5,c1,c9).$0()
else{c1.N()
g=A.a([],t.F)
b5=A.a([],t.s)
for(c8=t.K,c2=!1;;){c3=c1.K()
if(c3==null)break
if(!c2){b5=c3.gZ().aN(0)
c2=!0}c4=A.a([],c8)
for(l=b5.length,b7=0;b7<b5.length;b5.length===l||(0,A.n)(b5),++b7){k=c3.h(0,b5[b7])
c4.push(k==null?new A.d():k)}g.push(c4)}c1.L()
c5.cU(c9,b5,g)
return new A.B(b5,g,""+g.length+" rows returned.",B.f)}},
hD(a){var s,r,q,p,o,n,m,l,k,j
this.aZ()
s=this.a.d
s===$&&A.b()
r=s.iw(a)
r.N()
q=A.a([],t.F)
p=A.a([],t.s)
for(s=t.K,o=!1;;){n=r.K()
if(n==null)break
if(!o){p=n.gZ().aN(0)
o=!0}m=A.a([],s)
for(l=p.length,k=0;k<p.length;p.length===l||(0,A.n)(p),++k){j=n.h(0,p[k])
m.push(j==null?new A.d():j)}q.push(m)}r.L()
return new A.B(p,q,""+q.length+" rows returned.",B.f)},
hi(a){var s=this.c,r=a.a
if(!s.D(r))throw A.c(A.q("Variable '"+r+"' is not declared."))
s.k(0,r,this.f.J(a.b,new A.jR(a)).$1(s))},
hp(a){this.d.push(this.f.J(a.a,new A.k6(a)).$1(this.c).l(0))},
hB(){var s=A.a(["table_name","columns","type"],t.s),r=A.a([],t.F),q=this.a.b
q===$&&A.b()
q.c.a1(0,new A.kA(r))
return new A.B(s,r,""+r.length+" tables found.",B.f)},
hA(a){var s,r,q=A.a(["index_name","table_name","column_name","type"],t.s),p=A.a([],t.F),o=a.a,n=this.a.b
if(o!=null){n===$&&A.b()
s=n.bu(o)}else{n===$&&A.b()
o=n.e
n=A.E(o).i("b0<2>")
s=A.r(new A.b0(o,n),n.i("F.E"))}for(o=J.au(s),n=t.K;o.p();){r=o.gF()
p.push(A.a([new A.m(r.a),new A.m(r.b),new A.m(r.c),new A.m("B+ Tree")],n))}return new A.B(q,p,""+p.length+" indexes found.",B.f)},
d1(a){return this.hm(a)},
hm(h5){var s=0,r=A.b5(t.V),q,p=this,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2,b3,b4,b5,b6,b7,b8,b9,c0,c1,c2,c3,c4,c5,c6,c7,c8,c9,d0,d1,d2,d3,d4,d5,d6,d7,d8,d9,e0,e1,e2,e3,e4,e5,e6,e7,e8,e9,f0,f1,f2,f3,f4,f5,f6,f7,f8,f9,g0,g1,g2,g3,g4,g5,g6,g7,g8,g9,h0,h1,h2,h3,h4
var $async$d1=A.b6(function(h7,h8){if(h7===1)return A.b2(h8,r)
for(;;)switch(s){case 0:g8=h5.a
g9=g8.toLowerCase()
h0=h5.b
h1=h0.toLowerCase()
h2=h5.c
h3=h2.toLowerCase()
h4=p.a.b
h4===$&&A.b()
if(h4.e.D(g9.toLowerCase()))throw A.c(A.q("Index '"+g9+"' already exists."))
h4=p.a.b
h4===$&&A.b()
l=h4.c.h(0,h1.toLowerCase())
if(l==null)throw A.c(A.q("Table '"+h1+"' does not exist."))
k=h3.split(",")
j=A.a([],t.t)
for(h4=k.length,i=0;i<h4;++i){h=B.a.W(k[i])
g=l.dx
g===$&&A.b()
f=B.b.ad(g,h)
g=f===-1
if(g&&!B.a.E(h,"->")&&!B.a.E(h,"("))throw A.c(A.q("Column '"+h+"' does not exist in table '"+h1+"'."))
if(!g)j.push(f)}h4=h5.d
if(h4==null)e=null
else{g=A.S(h4,"_","").toLowerCase()
e=g}if(e==null)e=""
d=e==="hnsw"||e==="ivf"||e==="ivfflat"
g=l.d
if(g&&!d)throw A.c(A.q("B+ Tree indexes are not supported on columnar tables."))
c=p.a.b
c===$&&A.b()
c.f4(new A.b8(g8,h0,h2,h4),!0)
if(e==="ivf"||e==="ivfflat"){g8=p.a
h0=g8.a+"/"
b=A.q_(!1,h0+g9+".ivf_flat","euclidean")
a=j.length!==0?j[0]:0
if(g){g8=g8.c
g8===$&&A.b()
a0=h0+l.a+".col_"+a
a1=g8.a_(a0).a4()
for(a2=0;a2<a1;++a2){g8=p.a.c
g8===$&&A.b()
a3=g8.C(a0,a2)
g8=a3.c
g8===$&&A.b()
a4=g8.getUint16(1,!1)
for(a5=0;a5<a4;++a5){o=A.ab(a3,a5)
if(o!=null){a6=A.bV(A.aq(o,0,null),0,o.length)
if(a6 instanceof A.a5)b.b4(a6,a2,a5)}}g8=p.a.c
g8===$&&A.b()
g8.u(a0,a2,!1)}}b.bg()
q=new A.B(A.a([],t.s),A.a([],t.F),"IVF-FLAT Vector Index '"+g9+"' created successfully.",B.f)
s=1
break}if(h4==="hnsw"){a7=A.oL(!1,p.a.a+"/"+g9+".hnsw","euclidean")
a=j[0]
g8=p.a
h0=l.a
h2=g8.c
g8=g8.a
if(g){h2===$&&A.b()
a0=g8+"/"+h0+".col_"+a
a1=h2.a_(a0).a4()
for(a2=0;a2<a1;++a2){g8=p.a.c
g8===$&&A.b()
a3=g8.C(a0,a2)
g8=a3.c
g8===$&&A.b()
a4=g8.getUint16(1,!1)
for(a5=0;a5<a4;++a5){a8=5+a5*4
a9=g8.getUint16(a8,!1)
if(g8.getUint16(a8+2,!1)===0||a9>=4096)continue
o=A.ab(a3,a5)
if(o!=null){a6=A.bV(A.aq(o,0,null),0,o.length)
if(a6 instanceof A.a5)a7.b4(a6,a2,a5)}}g8=p.a.c
g8===$&&A.b()
g8.u(a0,a2,!1)}}else{h2===$&&A.b()
b0=A.aR(h2,g8,h0)
g8=p.a.c
g8===$&&A.b()
h0=b0.c+"/"+b0.b+".db"
a1=g8.a_(h0).a4()
for(a2=0;a2<a1;++a2){g8=p.a.c
g8===$&&A.b()
a3=g8.C(h0,a2)
g8=a3.c
g8===$&&A.b()
a4=g8.getUint16(1,!1)
for(a5=0;a5<a4;++a5){a8=5+a5*4
a9=g8.getUint16(a8,!1)
if(g8.getUint16(a8+2,!1)===0||a9>=4096)continue
o=A.ab(a3,a5)
if(o!=null){b1=A.a4(o,null,null)
if(a<b1.length){a6=b1[a]
if(a6 instanceof A.a5)a7.b4(a6,a2,a5)}}}g8=p.a.c
g8===$&&A.b()
g8.u(h0,a2,!1)}}a7.bg()
q=new A.B(A.a([],t.s),A.a([],t.F),"HNSW Vector Index '"+g9+"' created successfully.",B.f)
s=1
break}h0=p.a
h2=h0.c
h2===$&&A.b()
b2=A.h1(h2,h0.a+"/"+g9+".idx",k.length)
b2.ap()
b3=new A.bK()
$.cC()
b3.b7()
h0=p.a
h2=h0.c
h2===$&&A.b()
b0=A.aR(h2,h0.a,l.a)
h0=p.a.c
h0===$&&A.b()
h2=b0.c+"/"+b0.b+".db"
a1=h0.a_(h2).a4()
b4=k.length
h0=p.a.b
h0===$&&A.b()
b5=h0.aX(h1)
b6=b5.a
if(b6<=0&&a1>0)b6=a1*100
b7=new Float64Array(b6*b4)
b8=new Int32Array(b6)
b9=new Int32Array(b6)
h0=l.b
c0=h0.length
c1=new A.bK()
c1.b7()
h4=b4===1
c2=0
if(h4)if(j.length===0)for(g=t.N,c=t.r,c3=t.s,a2=0;a2<a1;++a2){c4=p.a.c
c4===$&&A.b()
a3=c4.C(h2,a2)
a4=a3.w
if(a4==null){c4=a3.c
c4===$&&A.b()
a4=a3.w=c4.getUint16(1,!1)}for(a5=0;a5<a4;++a5){o=A.ab(a3,a5)
if(o!=null){n=null
try{m=A.aV(o)
n=A.a4(m.d,null,null)}catch(h6){n=A.a4(o,null,null)}if(J.O(n)!==0){c6=A.o(g,c)
for(c7=0;c7<h0.length;++c7)c6.k(0,h0[c7],J.a_(n,c7))
c8=h3.split("->>")
if(c8.length===2){c4=c8[0]
c9=B.a.W(A.S(c4,"(",""))
c4=c8[1]
c4=A.S(c4,"'","")
c4=A.S(c4,'"',"")
c4=A.S(c4,")","")
d0=B.a.W(A.S(c4,"(",""))
d1=c6.h(0,c9)
if(d1 instanceof A.L){d2=d1.aV(A.a([d0],c3))
if(d2 instanceof A.p)d3=d2.a
else if(d2 instanceof A.j)d3=d2.a
else if(d2 instanceof A.m){d4=d2.a
d5=A.aH(d4)
if(d5!=null)d3=d5
else{for(c4=d4.length,d6=0,d7=0;d7<c4;++d7)d6=B.c.a7(d6*31+d4.charCodeAt(d7),9007199254740991)
d3=d6}}else d3=null
if(d3!=null){c4=b7.length
if(c2>=c4){d8=c4*2+100
d9=new Float64Array(d8)
e0=new Int32Array(d8)
e1=new Int32Array(d8)
B.ab.a8(d9,0,c4,b7)
B.E.a8(e0,0,b8.length,b8)
B.E.a8(e1,0,b9.length,b9)
b9=e1
b8=e0
b7=d9}b7.$flags&2&&A.i(b7)
b7[c2]=d3
b8.$flags&2&&A.i(b8)
b8[c2]=a2
b9.$flags&2&&A.i(b9)
b9[c2]=a5;++c2}}}}}}c4=p.a.c
c4===$&&A.b()
c4.u(h2,a2,!1)}else{e2=j[0]
for(h0=e2+1,g=e2*2,c=h0*2,a2=0;a2<a1;++a2){c3=p.a.c
c3===$&&A.b()
c3=c3.C(h2,a2).c
c3===$&&A.b()
a4=c3.getUint16(1,!1)
for(a5=0;a5<a4;++a5){a8=5+a5*4
a9=c3.getUint16(a8,!1)
e3=c3.getUint16(a8+2,!1)
if(e3===0||a9>=4096)continue
if(e3>=12){e4=a9+12
if(c3.getUint16(e4,!1)===c0)e5=e3-12
else{e5=e3
e4=a9}}else{e5=e3
e4=a9}e6=c3.getUint16(e4,!1)
if(e2>=e6)continue
c4=e4+2
e7=c3.getUint16(c4+g,!1)
e8=(h0<e6?c3.getUint16(c4+c,!1):e5)-e7
if(e8<=0)continue
e9=e4+e7
f0=c3.getUint8(e9)
if(f0===1){f1=e8-1
if(f1===1)d3=c3.getInt8(e9+1)
else if(f1===2)d3=c3.getInt16(e9+1,!1)
else if(f1===4)d3=c3.getInt32(e9+1,!1)
else d3=f1===8?B.r.c0(c3,e9+1).jd(0):null}else if(f0===2)d3=c3.getFloat64(e9+1,!1)
else if(f0===3){f2=J.bk(B.r.gai(c3),c3.byteOffset+(e9+1),e8-1)
d4=new A.d2(!1).bK(f2,0,null,!0)
d5=A.aH(d4)
if(d5!=null)d3=d5
else{for(c4=d4.length,d6=0,d7=0;d7<c4;++d7)d6=B.c.a7(d6*31+d4.charCodeAt(d7),9007199254740991)
d3=d6}}else d3=null
if(d3!=null){if(c2>=b6){f3=B.h.be(b6*1.5)+100
d9=new Float64Array(f3)
B.ab.a8(d9,0,c2,b7)
e0=new Int32Array(f3)
B.E.a8(e0,0,c2,b8)
e1=new Int32Array(f3)
B.E.a8(e1,0,c2,b9)
b9=e1
b8=e0
b7=d9
b6=f3}b7.$flags&2&&A.i(b7)
b7[c2]=d3
b8.$flags&2&&A.i(b8)
b8[c2]=a2
b9.$flags&2&&A.i(b9)
b9[c2]=a5;++c2}}c3=p.a.c
c3===$&&A.b()
c3.u(h2,a2,!1)}}else{f4=A.a9(b4,0,!1,t.i)
for(a2=0;a2<a1;++a2){h0=p.a.c
h0===$&&A.b()
h0=h0.C(h2,a2).c
h0===$&&A.b()
a4=h0.getUint16(1,!1)
for(a5=0;a5<a4;++a5){a8=5+a5*4
a9=h0.getUint16(a8,!1)
e3=h0.getUint16(a8+2,!1)
if(e3===0||a9>=4096)continue
if(e3>=12){e4=a9+12
if(h0.getUint16(e4,!1)===c0)e5=e3-12
else{e5=e3
e4=a9}}else{e5=e3
e4=a9}e6=h0.getUint16(e4,!1)
g=e4+2
c7=0
for(;;){f5=!1
if(!(c7<b4)){f5=!0
break}f=j[c7]
if(f===-1||f>=e6)break
e7=h0.getUint16(g+f*2,!1)
c=f+1
e8=(c<e6?h0.getUint16(g+c*2,!1):e5)-e7
if(e8<=0)break
e9=e4+e7
f0=h0.getUint8(e9)
if(f0===1){f1=e8-1
if(f1===1)d3=h0.getInt8(e9+1)
else if(f1===2)d3=h0.getInt16(e9+1,!1)
else if(f1===4)d3=h0.getInt32(e9+1,!1)
else d3=f1===8?B.r.c0(h0,e9+1).jd(0):null}else if(f0===2)d3=h0.getFloat64(e9+1,!1)
else if(f0===3){f2=J.bk(B.r.gai(h0),h0.byteOffset+(e9+1),e8-1)
d4=new A.d2(!1).bK(f2,0,null,!0)
d5=A.aH(d4)
if(d5!=null)d3=d5
else{for(c=d4.length,d6=0,d7=0;d7<c;++d7)d6=B.c.a7(d6*31+d4.charCodeAt(d7),9007199254740991)
d3=d6}}else d3=null
if(d3==null)break
f4[c7]=d3;++c7}if(f5){if(c2>=b6){f3=B.h.be(b6*1.5)+100
d9=new Float64Array(f3*b4)
B.ab.a8(d9,0,c2*b4,b7)
e0=new Int32Array(f3)
B.E.a8(e0,0,c2,b8)
e1=new Int32Array(f3)
B.E.a8(e1,0,c2,b9)
b9=e1
b8=e0
b7=d9
b6=f3}for(g=c2*b4,c=b7.$flags|0,c7=0;c7<b4;++c7){c3=f4[c7]
c&2&&A.i(b7)
b7[g+c7]=c3}b8.$flags&2&&A.i(b8)
b8[c2]=a2
b9.$flags&2&&A.i(b9)
b9[c2]=a5;++c2}}h0=p.a.c
h0===$&&A.b()
h0.u(h2,a2,!1)}}if(c1.b==null)c1.b=$.bs.$0()
A.cd("--> TIME: Extracting keys took: "+c1.gco()+"ms")
f6=new A.bK()
$.cC()
f6.b7()
h0=c2===b6
if(h0)f7=b7
else f7=h4?A.pT(b7,0,c2):A.pT(b7,0,c2*b4)
f8=h0?b8:A.pW(b8,0,c2)
f9=h0?b9:A.pW(b9,0,c2)
g0=new Int32Array(c2)
for(c7=0;c7<c2;++c7)g0[c7]=c7
h0=c2-1
if(h4)A.pl(g0,f7,f8,f9,0,h0)
else A.pm(g0,f7,f8,f9,b4,0,h0)
if(f6.b==null)f6.b=$.bs.$0()
A.cd("--> TIME: Sorting indices took: "+f6.gco()+"ms")
b5.a=c2
h2=""+c2
A.cd("Calling btree.insertSortedBatchSync with actualRowCount = "+h2)
g1=new A.bK()
$.cC()
g1.b7()
b2.fn(f7,f8,f9,b4,g0)
if(g1.b==null)g1.b=$.bs.$0()
A.cd("--> TIME: B-Tree insertSortedBatchSync took: "+g1.gco()+"ms")
if(b3.b==null)b3.b=$.bs.$0()
A.cd("--> TIME: TOTAL CREATE INDEX took: "+b3.gco()+"ms")
g2=b5.b.J(h3,new A.jW())
g=c2>0
if(g){g3=1
if(h4){for(c7=1;c7<c2;++c7)if(f7[g0[c7]]!==f7[g0[c7-1]])++g3}else for(c7=1;c7<c2;++c7){h4=g0[c7]*b4
c=g0[c7-1]*b4
g5=0
for(;;){if(!(g5<b4)){g4=!1
break}if(f7[h4+g5]!==f7[c+g5]){g4=!0
break}++g5}if(g4)++g3}}else g3=0
g2.c+=g3
if(g){g6=f7[g0[0]*b4]
g7=f7[g0[h0]*b4]
h0=g2.a
if(h0==null||g6<h0)g2.a=g6
h0=g2.b
if(h0==null||g7>h0)g2.b=g7}b5.a=c2
q=new A.B(A.a([],t.s),A.a([],t.F),"Index '"+g8+"' created successfully on '"+h1+"("+h3+")' ("+h2+" rows indexed).",B.f)
s=1
break
case 1:return A.b3(q,r)}})
return A.b4($async$d1,r)},
hx(a1){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0=this
for(j=a1.b,i=j.length,h=a0.cx,g=0;g<j.length;j.length===i||(0,A.n)(j),++g){f=j[g]
e=f.a
h.k(0,e.toLowerCase(),new A.i5(e,f.b))}for(j=a1.a,i=j.length,h=a0.c,e=a0.f,g=0;g<j.length;j.length===i||(0,A.n)(j),++g){d=j[g]
c=new A.d()
b=d.c
if(b!=null){c=e.J(b,new A.kr(d)).$1(h)
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
i.c3(j)}r=null
if(s){j=a1.d
j=j!=null&&j.length!==0}else j=!1
if(j){j=$.pX
$.pX=j+1
r="_auto_sp_"+j
j=a0.a
i=j.c
i===$&&A.b()
h=r
j=j.b
j===$&&A.b()
i.fd(h,j)}q=null
try{for(j=a1.c,i=j.length,g=0;g<j.length;j.length===i||(0,A.n)(j),++g){p=j[g]
o=a0.aB(p)
if(o instanceof A.ad){j=A.q("Asynchronous operations are not supported inside PL/SQL blocks.")
throw A.c(j)}if(o instanceof A.B)q=o}a0.aZ()
a0.aS()
if(!s){j=a0.a.c
j===$&&A.b()
j.ck()}}catch(a){n=A.aU(a)
B.b.v(a0.e)
a0.aS()
if(!s){j=a0.a
i=j.c
i===$&&A.b()
j=j.b
j===$&&A.b()
i.bF(j)}else if(r!=null){j=a0.a
i=j.c
i===$&&A.b()
h=r
j=j.b
j===$&&A.b()
i.fu(h,j)}a0.r.v(0)
j=a1.d
if(j!=null&&j.length!==0){m=B.b.iI(j,new A.ks(n),new A.kt(a1))
for(j=m.b,i=j.length,g=0;g<j.length;j.length===i||(0,A.n)(j),++g){l=j[g]
k=a0.aB(l)
if(k instanceof A.ad)throw A.c(A.q("Asynchronous operations are not supported inside exception handlers."))
if(k instanceof A.B)q=k}}else throw a}j=q
return j==null?new A.B(A.a([],t.s),A.a([],t.F),"PL/SQL block executed successfully.",B.f):j},
hw(a){var s,r,q,p,o,n=this,m=n.f,l=n.c,k=m.J(a.a,new A.kd(a)).$1(l)
if(k instanceof A.p&&k.a===1){for(m=a.b,l=m.length,s=0;s<m.length;m.length===l||(0,A.n)(m),++s)if(n.aB(m[s]) instanceof A.ad)throw A.c(A.q("Asynchronous operations are not supported inside IF branches."))
return}for(r=a.c,q=r.length,s=0;s<r.length;r.length===q||(0,A.n)(r),++s){p=r[s]
o=m.J(p.a,new A.ke(p)).$1(l)
if(o instanceof A.p&&o.a===1){for(m=p.b,l=m.length,s=0;s<m.length;m.length===l||(0,A.n)(m),++s)if(n.aB(m[s]) instanceof A.ad)throw A.c(A.q("Asynchronous operations are not supported inside ELSIF branches."))
return}}m=a.d
if(m!=null)for(l=m.length,s=0;s<m.length;m.length===l||(0,A.n)(m),++s)if(n.aB(m[s]) instanceof A.ad)throw A.c(A.q("Asynchronous operations are not supported inside ELSE branches."))},
hG(a){var s,r,q,p,o,n=this.f.J(a.a,new A.kM(a))
for(s=a.b,r=this.c;;){q=n.$1(r)
if(q instanceof A.p&&q.a===1){for(p=s.length,o=0;o<s.length;s.length===p||(0,A.n)(s),++o)if(this.aB(s[o]) instanceof A.ad)throw A.c(A.q("Asynchronous operations are not supported inside WHILE loops."))}else break}},
aZ(){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2,b3,b4,b5=this,b6=b5.e,b7=b6.length
if(b7===0)return
s=A.o(t.N,t.aQ)
for(r=0;r<b6.length;b6.length===b7||(0,A.n)(b6),++r){q=b6[r]
J.ae(s.J(q.a,new A.kN()),q)}for(b7=new A.am(s,s.$ti.i("am<1,2>")).gI(0);b7.p();){p=b7.d
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
break}}if(!l)k.ar(m,new A.kO())
if(k.gaa(m)&&k.h(m,0).d.length!==0){n.ap()
b=n.iT(k.h(m,0).d[0])}else b=!1
if(b){a=b5.a.b
a===$&&A.b()
a0=a.aX(k.h(m,0).b).b.J(k.h(m,0).c,new A.kP())
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
if(a6==null||!b5.h2(a6,a8)){++a5
a6=a8}}n.iN(a2,a3,a4,a1)
a0.c+=a5
if(k.gaa(m)&&k.gH(m).d.length!==0){b0=k.gH(m).d[0]
b1=k.gV(m).d[0]
k=a0.a
if(k==null||b0<k)a0.a=b0
k=a0.b
if(k==null||b1>k)a0.b=b1}}else for(k=k.gI(m);k.p();){a=k.gF()
b2=a.d
if(n.b4(b2,a.e,a.f)){b3=b5.a.b
b3===$&&A.b()
a0=b3.aX(a.b).b.J(a.c,new A.kQ());++a0.c
if(b2.length!==0){b4=b2[0]
a=a0.a
if(a==null||b4<a)a0.a=b4
a=a0.b
if(a==null||b4>a)a0.b=b4}}}}b5.aS()
B.b.v(b6)},
aS(){for(var s=this.r,s=new A.an(s,s.r,s.e,A.E(s).i("an<2>"));s.p();)s.d.bE()
s=this.a.c
s===$&&A.b()
s.iY()},
cd(){var s,r
for(s=this.r,s=new A.an(s,s.r,s.e,A.E(s).i("an<2>"));s.p();){r=s.d
if(r.r!=null){r.a.u(r.c+"/"+r.b+".db",r.w,!1)
r.r=null
r.w=-1}r.f=null}},
hh(b6){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2=this,b3=null,b4=b6.a.toLowerCase(),b5=b2.a.b
b5===$&&A.b()
m=b5.c.h(0,b4.toLowerCase())
if(m==null)throw A.c(A.q("Table '"+b4+"' does not exist."))
if(m.d)throw A.c(A.q("Analyze is not supported on columnar tables."))
b5=b2.a.b
b5===$&&A.b()
l=b5.aX(m.a)
l.a=0
b5=l.b
b5.v(0)
k=b2.r.J(b4,new A.jQ(b2,m))
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
a1=a0.w
if(a1==null){f=a0.c
f===$&&A.b()
a1=a0.w=f.getUint16(1,!1)}for(a2=0;a2<a1;++a2){p=A.ab(a0,a2)
if(p!=null){o=null
try{n=A.aV(p)
if(q.aD(n.a,n.b,s,r))o=A.a4(n.d,b3,b3)}catch(a3){o=A.a4(p,b3,b3)}if(o!=null){++l.a
for(e=0;e<j.length;++e)if(e<J.O(o)){a4=J.a_(o,e)
if(!(a4 instanceof A.d))g.h(0,e).R(0,a4)}}}}f=b2.a.c
f===$&&A.b()
f.u(i,a,!1)}for(e=0;e<j.length;++e){i=j[e]
a5=g.h(0,e)
f=a5.a
if(f!==0){a6=new A.bq(b3,b3,0)
a6.c=f
for(f=A.E(a5),a7=new A.c9(a5,a5.r,f.i("c9<1>")),a7.c=a5.e,f=f.c,a8=b3,a9=a8;a7.p();){b0=a7.d
b1=(b0==null?f.a(b0):b0).ga2()
if(typeof b1=="number"){if(a9==null||b1<a9)a9=b1
if(a8==null||b1>a8)a8=b1}}a6.a=a9
a6.b=a8
b5.k(0,i.toLowerCase(),a6)}}b5=b2.a.b
b5===$&&A.b()
b5.aF()
return new A.B(A.a(["status"],t.s),A.a([A.a([new A.m("SUCCESS")],t.K)],t.F),"Analyzed table '"+b4+"'. Row count: "+l.a+".",B.f)},
cU(a6,a7,a8){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4=this,a5=a4.b
if(a5==="admin"||a5==="system")return
a5=a7.length
s=A.a9(a5,null,!1,t.T)
r=a6.a
if(r.length===1){q=r[0].a
q=q instanceof A.I&&B.b.gH(q.b)==="*"}else q=!1
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
k=B.b.ad(l,m.toLowerCase())
if(k!==-1)s[n]=q[k]
else s[n]=q[n];++n}}}else{q=a6.f
j=a6.b
n=0
for(;;){if(!(n<a7.length&&n<r.length))break
i=r[n].a
if(i instanceof A.I){o=i.b
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
g=B.b.gV(o)}else g=""
if(h!=null){o=a4.a.b
o===$&&A.b()
p=o.c.h(0,h.toLowerCase())
if(p!=null){o=p.dx
o===$&&A.b()
k=B.b.ad(o,g.toLowerCase())
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
hu(a){var s,r,q,p,o,n,m,l,k,j=this.f,i=j.J(a.b,new A.kb(a)),h=j.J(a.c,new A.kc(a))
j=this.c
s=i.$1(j)
r=h.$1(j)
q=s instanceof A.p?s.a:A.d8(s.l(0))
p=r instanceof A.p?r.a:A.d8(r.l(0))
for(o=a.d,n=a.a,m=q;m<=p;++m){j.k(0,n,A.v(m))
for(l=o.length,k=0;k<o.length;o.length===l||(0,A.n)(o),++k)this.aB(o[k])}return new A.B(A.a([],t.s),A.a([],t.F),"FOR loop executed.",B.f)},
hs(a){var s,r=this,q="' does not exist.",p=a.a,o=r.bJ(p),n=r.a.b
n===$&&A.b()
if(!n.c.D(o.toLowerCase())){if(a.b)return new A.B(A.a([],t.s),A.a([],t.F),"Table '"+p+q,B.f)
throw A.c(A.q("Table '"+p+q))}r.aS()
r.cd()
n=r.r
n.T(0,o)
n.T(0,p.toLowerCase())
n=r.a.b
n===$&&A.b()
n.c.T(0,o.toLowerCase())
n.aF()
n=r.a
s=n.c
s===$&&A.b()
s.iF(n.a+"/"+o+".db")
r.Q.v(0)
r.as.v(0)
$.eB.v(0)
r.f.v(0)
r.CW.v(0)
return new A.B(A.a([],t.s),A.a([],t.F),"Table '"+p+"' dropped successfully.",B.f)},
hr(a){return new A.B(A.a([],t.s),A.a([],t.F),"Index '"+a.a+"' dropped successfully.",B.f)},
bJ(a){var s,r=B.a.W(a),q=r.length
if(q>=2)if(!(B.a.U(r,"'")&&B.a.B(r,"'")))s=B.a.U(r,'"')&&B.a.B(r,'"')
else s=!0
else s=!1
if(s)r=B.a.O(r,1,q-1)
return r.toLowerCase()},
eg(a){var s,r,q,p,o,n=a.a,m=this.bJ(n),l=this.a.b
l===$&&A.b()
s=l.c.h(0,m.toLowerCase())
if(s==null)throw A.c(A.q("Table '"+n+"' does not exist."))
r=A.a(["column_name","data_type","nullable"],t.s)
q=A.a([],t.F)
for(n=s.b,l=s.c,p=t.K,o=0;o<n.length;++o)q.push(A.a([new A.m(n[o]),new A.m(l[o].b.toUpperCase()),new A.m("YES")],p))
return new A.B(r,q,""+q.length+" columns described.",B.f)},
hy(a){var s,r,q,p,o,n=a.a,m=this.bJ(n),l=this.a.b
l===$&&A.b()
s=l.c.h(0,m.toLowerCase())
if(s==null)throw A.c(A.q("Table '"+n+"' does not exist."))
r=A.a(["cid","name","type","notnull","dflt_value","pk"],t.s)
q=A.a([],t.F)
for(n=s.b,l=s.c,p=t.K,o=0;o<n.length;++o)q.push(A.a([A.v(o),new A.m(n[o]),new A.m(l[o].b.toUpperCase()),A.v(0),new A.d(),A.v(0)],p))
return new A.B(r,q,""+q.length+" columns found.",B.f)},
hC(a){var s=this,r=a.a,q=s.bJ(r),p=s.a.b
p===$&&A.b()
if(p.c.h(0,q.toLowerCase())==null)throw A.c(A.q("Table '"+q+"' does not exist."))
s.aS()
s.cd()
p=s.r
p.T(0,q)
p.T(0,r.toLowerCase())
s.a.cB(q)
return new A.B(A.a([],t.s),A.a([],t.F),"Table '"+q+"' truncated successfully.",B.f)}}
A.kR.prototype={
$0(){var s,r,q,p,o,n=this.a.a.b
n===$&&A.b()
n=n.c
n=new A.an(n,n.r,n.e,A.E(n).i("an<2>"))
s=this.b
while(n.p())for(r=n.d.r,q=r.length,p=0;p<q;++p){o=r[p]
if(o!=null&&o.toLowerCase()===s)return!0}return!1},
$S:72}
A.kT.prototype={
$0(){var s=0,r=A.b5(t.V),q,p=2,o=[],n=this,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1
var $async$$0=A.b6(function(b2,b3){if(b2===1){o.push(b3)
s=p}for(;;)switch(s){case 0:a8=$.oJ
a9=$.pR=n.b
if(!a8)B.b.v($.pS)
a8=new A.bK()
$.cC()
a8.b7()
$.oK=a8
$.oJ=!0
a=new A.bK()
a.b7()
m=a
a8=n.a
a0=a8.d
B.b.v(a0)
a8.c.v(0)
l=!1
a1=a9.toLowerCase()
if(B.a.E(a1,"insert")||B.a.E(a1,"update")||B.a.E(a1,"delete")||B.a.E(a1,"create")||B.a.E(a1,"alter")||B.a.E(a1,"drop")){a2=a8.a.e
a2===$&&A.b()
a2.j_(a8.b,a9)}p=4
k=null
if($.eB.D(a9)){a9=$.eB.h(0,a9)
a9.toString
k=a9}else{j=new A.c1(a9)
i=j.bt()
a2=i
a3=A.z(a2).i("aJ<1>")
a4=A.r(new A.aJ(a2,new A.kS(),a3),a3.i("F.E"))
h=a4
if(J.O(h)!==0){a9=A.q("Lexer error: "+J.e6(h).b+" at Line "+J.e6(h).c+":"+J.e6(h).d)
throw A.c(a9)}g=new A.c3(i)
k=g.fs()
if(!B.a.E(a9.toLowerCase(),"set engine_option"))$.eB.k(0,a9,k)}if(J.O(k)===0){a9=A.q("No SQL statements found to execute.")
throw A.c(a9)}f=null
a9=t.s
e=A.a([],a9)
a2=k,a3=a2.length,a5=0
case 7:if(!(a5<a2.length)){s=9
break}d=a2[a5]
p=11
if(d instanceof A.dk||d instanceof A.dj||d instanceof A.dh||d instanceof A.di||d instanceof A.cG||d instanceof A.cF||d instanceof A.bR)l=!0
c=a8.aB(d)
s=c instanceof A.ad?14:15
break
case 14:s=16
return A.as(c,$async$$0)
case 16:c=b3
case 15:if(c instanceof A.B){f=c
if(c.c.length!==0)J.ae(e,c.c)}p=4
s=13
break
case 11:p=10
b0=o.pop()
B.b.v(a8.e)
a8.aS()
a9=a8.a
a0=a9.c
a0===$&&A.b()
a9=a9.b
a9===$&&A.b()
a0.bF(a9)
throw b0
s=13
break
case 10:s=4
break
case 13:case 8:a2.length===a3||(0,A.n)(a2),++a5
s=7
break
case 9:a8.aZ()
a8.aS()
if(l){a2=a8.a.b
a2===$&&A.b()
a2.aF()
a8.ay.v(0)
a8.Q.v(0)
a8.as.v(0)
$.eB.v(0)
a8.f.v(0)
a8.CW.v(0)}a2=a8.a.c
a2===$&&A.b()
if(a2.gab()==null){a2=a8.a.c
a2===$&&A.b()
a2.bc()}a2=m
if(a2.b==null)a2.b=$.bs.$0()
a2=f
a2=a2==null?null:a2.b.length
A.t8(a2==null?0:a2)
b=J.oy(e,"\n")
if(f!=null){a9=f.a
a2=f.b
a3=J.O(b)===0?"Script executed successfully.":b
a7=A.j2(0,m.gbB())
A.a6(a0,!0,t.N)
q=new A.B(a9,a2,a3,a7)
s=1
break}a9=A.a([],a9)
a2=A.a([],t.F)
a3=J.O(b)===0?"Statement executed successfully.":b
a7=A.j2(0,m.gbB())
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
if(a9.b==null)a9.b=$.bs.$0()
B.b.v(a8.e)
a8.aS()
a8=a8.a
a9=a8.c
a9===$&&A.b()
a8=a8.b
a8===$&&A.b()
a9.bF(a8)
throw b1
s=6
break
case 3:s=2
break
case 6:case 1:return A.b3(q,r)
case 2:return A.b2(o.at(-1),r)}})
return A.b4($async$$0,r)},
$S:39}
A.kS.prototype={
$1(a){return a.a===B.K},
$S:74}
A.kp.prototype={
$0(){return A.K(this.a.a)},
$S:0}
A.kq.prototype={
$1(a){var s=this.a
return s.f.J(a,new A.ko(a)).$1(s.c)},
$S:19}
A.ko.prototype={
$0(){return A.K(this.a)},
$S:0}
A.jT.prototype={
$1(a){var s=this.a
return s.f.J(a,new A.jS(a)).$1(s.c)},
$S:19}
A.jS.prototype={
$0(){return A.K(this.a)},
$S:0}
A.jY.prototype={
$1(a){return a.b===B.W},
$S:11}
A.jZ.prototype={
$1(a){return a.a},
$S:46}
A.k_.prototype={
$1(a){return a.b},
$S:57}
A.k0.prototype={
$1(a){return a.c},
$S:11}
A.k1.prototype={
$1(a){return a.d},
$S:11}
A.k2.prototype={
$1(a){return a.e},
$S:21}
A.k3.prototype={
$1(a){return a.f},
$S:21}
A.k4.prototype={
$1(a){return a.r},
$S:11}
A.k5.prototype={
$1(a){return a.y},
$S:21}
A.jU.prototype={
$1(a){return a.a},
$S:46}
A.jV.prototype={
$1(a){return a.b},
$S:57}
A.jX.prototype={
$1(a){return a.a.toLowerCase()===this.a.a.toLowerCase()},
$S:88}
A.kB.prototype={
$0(){var s=this.a.c
s.toString
return A.K(s)},
$S:0}
A.kg.prototype={
$0(){var s,r=this.b.a.toLowerCase(),q=this.a.a.b
q===$&&A.b()
s=q.c.h(0,r.toLowerCase())
if(s==null)throw A.c(A.q("Table '"+r+"' does not exist."))
return s},
$S:89}
A.kh.prototype={
$0(){var s=J.bG(this.a.b,new A.kf(),t.W)
s=A.r(s,s.$ti.i("u.E"))
return s},
$S:90}
A.kf.prototype={
$1(a){return A.K(a)},
$S:14}
A.ki.prototype={
$0(){var s=this.b.a,r=s.c
r===$&&A.b()
return A.aR(r,s.a,this.a.a.a)},
$S:6}
A.kj.prototype={
$0(){var s=this.b.a,r=s.c
r===$&&A.b()
return A.aR(r,s.a,this.a.a.a)},
$S:6}
A.kk.prototype={
$0(){var s=this.a.a,r=s.c
r===$&&A.b()
return A.aR(r,s.a,this.b.a)},
$S:6}
A.kl.prototype={
$0(){var s=this.b.a,r=s.c
r===$&&A.b()
return new A.bS(r,this.a.a.a,s.a)},
$S:103}
A.km.prototype={
$0(){var s=this.b.a,r=s.c
r===$&&A.b()
return A.aR(r,s.a,this.a.a.a)},
$S:6}
A.kn.prototype={
$0(){return this.a.a.toLowerCase()},
$S:35}
A.k7.prototype={
$0(){var s=this.a.a,r=s.c
r===$&&A.b()
return A.aR(r,s.a,this.b.a)},
$S:6}
A.k8.prototype={
$0(){return A.K(this.a.d)},
$S:0}
A.k9.prototype={
$0(){var s,r,q,p=A.o(t.N,t.S)
for(s=0,r=this.a,q=r.b,r=r.a+".";s<q.length;++s){J.aX(p,r+q[s],s)
J.aX(p,q[s],s)}return p},
$S:23}
A.ka.prototype={
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
return A.aR(r,s.a,this.b.a)},
$S:6}
A.kE.prototype={
$2(a,b){var s=B.c.A(a.a,b.a)
if(!J.az(s,0))return s
return B.c.A(a.b,b.b)},
$S:32}
A.kF.prototype={
$0(){var s,r,q,p=A.o(t.N,t.S)
for(s=0,r=this.a,q=r.b,r=r.a+".";s<q.length;++s){J.aX(p,r+q[s],s)
J.aX(p,q[s],s)}return p},
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
for(s=0,r=this.a,q=r.b,r=r.a+".";s<q.length;++s){J.aX(p,r+q[s],s)
J.aX(p,q[s],s)}return p},
$S:23}
A.kJ.prototype={
$0(){return this.a.a.toLowerCase()},
$S:35}
A.kK.prototype={
$1(a){return B.a.W(a).toLowerCase()},
$S:7}
A.kL.prototype={
$1(a){return a.toLowerCase()===this.a},
$S:8}
A.jP.prototype={
$0(){var s=this.a.a,r=s.c
r===$&&A.b()
return A.aR(r,s.a,this.b.a)},
$S:6}
A.ku.prototype={
$2(a,b){this.a.push(A.a([new A.m("ultsql"),new A.m("public"),new A.m(b.a),new A.m("BASE TABLE"),new A.aG(b.d)],t.K))},
$S:24}
A.kv.prototype={
$2(a,b){var s,r,q,p,o,n,m
for(s=b.b,r=this.a,q=b.a,p=b.c,o=t.K,n=0;n<s.length;n=m){m=n+1
r.push(A.a([new A.m("ultsql"),new A.m("public"),new A.m(q),new A.m(s[n]),A.v(m),new A.m(p[n].b.toUpperCase()),new A.m("YES")],o))}},
$S:24}
A.kw.prototype={
$1(a){return new A.ai(new A.I(A.a([a],t.s)),null)},
$S:123}
A.kz.prototype={
$1(a){var s=this
if(a instanceof A.dK)return!0
if(a instanceof A.ci)return s.$1(a.a)
if(a instanceof A.co)return s.$1(a.a)
if(a instanceof A.bY)return s.$1(a.a)
if(a instanceof A.dS)return s.$1(a.a)
if(a instanceof A.cP)return s.$1(a.a)
if(a instanceof A.dw)return s.$1(a.a)||s.$1(a.b)
if(a instanceof A.dx)return s.$1(a.a)
if(a instanceof A.dv)return s.$1(a.a)
return!1},
$S:126}
A.kx.prototype={
$0(){var s=0,r=A.b5(t.V),q,p=this,o,n,m,l,k,j,i,h,g,f,e
var $async$$0=A.b6(function(a,b){if(a===1)return A.b2(b,r)
for(;;)switch(s){case 0:f=p.a
e=f.a.c
e===$&&A.b()
e.bc()
e=p.b
s=3
return A.as(new A.ky().$1(e),$async$$0)
case 3:e.N()
o=A.a([],t.F)
n=A.a([],t.s)
for(m=t.K,l=!1;;){k=e.K()
if(k==null)break
if(!l){n=k.gZ().aN(0)
l=!0}j=A.a([],m)
for(i=n.length,h=0;h<n.length;n.length===i||(0,A.n)(n),++h){g=k.h(0,n[h])
j.push(g==null?new A.d():g)}o.push(j)}e.L()
f.cU(p.c,n,o)
q=new A.B(n,o,""+o.length+" rows returned.",B.f)
s=1
break
case 1:return A.b3(q,r)}})
return A.b4($async$$0,r)},
$S:39}
A.ky.prototype={
fF(a){var s=0,r=A.b5(t.H),q=this
var $async$$1=A.b6(function(b,c){if(b===1)return A.b2(c,r)
for(;;)switch(s){case 0:s=a instanceof A.dK?2:4
break
case 2:s=5
return A.as(a.cr(),$async$$1)
case 5:s=3
break
case 4:s=a instanceof A.ci?6:8
break
case 6:s=9
return A.as(q.$1(a.a),$async$$1)
case 9:s=7
break
case 8:s=a instanceof A.co?10:12
break
case 10:s=13
return A.as(q.$1(a.a),$async$$1)
case 13:s=11
break
case 12:s=a instanceof A.bY?14:16
break
case 14:s=17
return A.as(q.$1(a.a),$async$$1)
case 17:s=15
break
case 16:s=a instanceof A.dS?18:20
break
case 18:s=21
return A.as(q.$1(a.a),$async$$1)
case 21:s=19
break
case 20:s=a instanceof A.cP?22:24
break
case 22:s=25
return A.as(q.$1(a.a),$async$$1)
case 25:s=23
break
case 24:s=a instanceof A.dw?26:28
break
case 26:s=29
return A.as(q.$1(a.a),$async$$1)
case 29:s=30
return A.as(q.$1(a.b),$async$$1)
case 30:s=27
break
case 28:s=a instanceof A.dx?31:33
break
case 31:s=34
return A.as(q.$1(a.a),$async$$1)
case 34:s=32
break
case 33:s=a instanceof A.dv?35:36
break
case 35:s=37
return A.as(q.$1(a.a),$async$$1)
case 37:case 36:case 32:case 27:case 23:case 19:case 15:case 11:case 7:case 3:return A.b3(null,r)}})
return A.b4($async$$1,r)},
$1(a){return this.fF(a)},
$S:127}
A.jR.prototype={
$0(){return A.K(this.a.b)},
$S:0}
A.k6.prototype={
$0(){return A.K(this.a.a)},
$S:0}
A.kA.prototype={
$2(a,b){var s=B.b.S(b.b,", "),r=b.d?"Columnar":"Row"
this.a.push(A.a([new A.m(b.a),new A.m(s),new A.m(r)],t.K))},
$S:24}
A.jW.prototype={
$0(){return new A.bq(null,null,0)},
$S:25}
A.kr.prototype={
$0(){var s=this.a.c
s.toString
return A.K(s)},
$S:0}
A.ks.prototype={
$1(a){var s=a.a
return s.toLowerCase()==="others"||B.a.E(J.x(this.a).toLowerCase(),s.toLowerCase())},
$S:60}
A.kt.prototype={
$0(){var s=this.a.d
s.toString
return B.b.gH(s)},
$S:61}
A.kd.prototype={
$0(){return A.K(this.a.a)},
$S:0}
A.ke.prototype={
$0(){return A.K(this.a.a)},
$S:0}
A.kM.prototype={
$0(){return A.K(this.a.a)},
$S:0}
A.kN.prototype={
$0(){return A.a([],t.f0)},
$S:62}
A.kO.prototype={
$2(a,b){var s,r,q=a.d,p=q.length,o=b.d,n=o.length,m=p<n?p:n
for(s=0;s<m;++s){r=B.h.A(q[s],o[s])
if(r!==0)return r}return B.c.A(p,n)},
$S:63}
A.kP.prototype={
$0(){return new A.bq(null,null,0)},
$S:25}
A.kQ.prototype={
$0(){return new A.bq(null,null,0)},
$S:25}
A.jQ.prototype={
$0(){var s=this.a.a,r=s.c
r===$&&A.b()
return A.aR(r,s.a,this.b.a)},
$S:6}
A.kb.prototype={
$0(){return A.K(this.a.b)},
$S:0}
A.kc.prototype={
$0(){return A.K(this.a.c)},
$S:0}
A.bu.prototype={}
A.o3.prototype={
$1(a){return A.cA(B.a.W(a))},
$S:9}
A.cw.prototype={}
A.i5.prototype={}
A.lL.prototype={
$1(a){var s,r,q,p,o=this,n=o.a
if(n.b)return o.b.$1(a)
s=n.a
if(s!=null){r=a.h(0,s)
if(r!=null)return r}s=o.c
if(a.D(s)){n.a=s
n=a.h(0,s)
n.toString
return n}q=s.toLowerCase()
for(s=a.gZ(),s=s.gI(s);s.p();){p=s.gF()
if(p.toLowerCase()===q){n.a=p
s=a.h(0,p)
s.toString
return s}}n.b=!0
return o.b.$1(a)},
$S:1}
A.la.prototype={
$1(a){var s,r,q,p,o=$.cN
if(o==null)return new A.d()
$.cU.push(a)
try{s=o.aB(this.a.b)
if(s!=null){r=s.gfw()
if(t.j.b(r)){if(J.O(r)===0){q=A.a([],t.K)
return new A.aO(q)}if(J.O(r)===1&&J.a_(r,0).length===1){q=J.a_(r,0)[0]
return q}q=r
p=A.z(q).i("h<1,k>")
q=A.r(new A.h(q,new A.l9(),p),p.i("u.E"))
return new A.aO(q)}}return new A.d()}finally{if($.cU.length!==0)$.cU.pop()}},
$S:1}
A.l9.prototype={
$1(a){var s=J.X(a)
return s.gaa(a)?t.r.a(s.h(a,0)):new A.d()},
$S:52}
A.lb.prototype={
$1(a){var s,r,q,p=this,o=null,n=p.a.$1(a)
if(n instanceof A.L){s=n.ga2()
if(t.f.b(s))r=s.h(0,p.b)
else if(t.j.b(s)){q=A.a3(p.b,o)
r=q!=null&&q>=0&&q<J.O(s)?J.a_(s,q):o}else r=o
if(r==null)return new A.d()
if(p.c)if(typeof r=="string")return new A.m(r)
else return new A.m(B.o.bC(r))
else if(A.fQ(r))return A.v(r)
else if(typeof r=="number")return new A.j(r)
else if(typeof r=="number")return new A.j(r)
else if(A.fP(r))return A.v(r?1:0)
else return new A.L(r,o)}return new A.d()},
$S:1}
A.lc.prototype={
$1(a){return new A.d()},
$S:1}
A.ln.prototype={
$1(a){return this.a},
$S:1}
A.ly.prototype={
$1(a){return this.a},
$S:67}
A.lD.prototype={
$1(a){return new A.d()},
$S:27}
A.lE.prototype={
$1(a){return new A.L(!0,null)},
$S:33}
A.lF.prototype={
$1(a){return new A.L(!1,null)},
$S:33}
A.lG.prototype={
$1(a){var s,r,q,p,o,n,m,l,k,j,i,h,g=this,f=g.a,e=f.a
if(e!=null&&a instanceof A.aN){s=a.a[e]
if(g.b&&s instanceof A.L&&f.c<g.c.length)return s.aV(B.b.ac(g.c,f.c))
return s}e=f.b
if(e!=null){if(a instanceof A.aN){r=a.b.h(0,e)
if(r!=null){f.a=r
s=a.a[r]
if(g.b&&s instanceof A.L&&f.c<g.c.length)return s.aV(B.b.ac(g.c,f.c))
return s}}s=a.h(0,f.b)
if(s==null)return new A.d()
if(g.b&&s instanceof A.L&&f.c<g.c.length)return s.aV(B.b.ac(g.c,f.c))
return s}q=B.b.S(g.d.b,".")
if(a.D(q)){f.b=q
f.c=g.c.length
f=a.h(0,q)
f.toString
return f}p=q.toLowerCase()
for(e=a.gZ(),e=e.gI(e);e.p();){o=e.gF()
if(o.toLowerCase()===p){f.b=o
f.c=g.c.length
e=a.h(0,o)
e.toString
return e}}e=g.c
if(e.length>=2){n=e[0]+"."+e[1]
if(a.D(n)){f.b=n
f.c=2
f=a.h(0,n)
f.toString
if(e.length>2&&f instanceof A.L)return f.aV(B.b.ac(e,2))
return f}m=e[1].toLowerCase()
for(o=a.gZ(),o=o.gI(o),l="."+m;o.p();){k=o.gF()
j=k.toLowerCase()
if(j===m||B.a.B(j,l)){f.b=k
f.c=2
o=a.h(0,k)
o.toString
if(e.length>2&&o instanceof A.L)return o.aV(B.b.ac(e,2))
return o}}}i=e[0].toLowerCase()
for(o=a.gZ(),o=o.gI(o),l="."+i;o.p();){k=o.gF()
j=k.toLowerCase()
if(j===i||B.a.B(j,l)){f.b=k
f.c=1
o=a.h(0,k)
o.toString
if(e.length>1&&o instanceof A.L)return o.aV(B.b.ac(e,1))
return o}}h=A.qm(q)
if(h!=null)return h
return new A.d()},
$S:1}
A.lH.prototype={
$1(a){return J.rF(this.a.$1(a),this.b.$1(a))},
$S:1}
A.lI.prototype={
$1(a){return J.rI(this.a.$1(a),this.b.$1(a))},
$S:1}
A.ld.prototype={
$1(a){return J.rH(this.a.$1(a),this.b.$1(a))},
$S:1}
A.le.prototype={
$1(a){return J.rG(this.a.$1(a),this.b.$1(a))},
$S:1}
A.lf.prototype={
$1(a){var s=a.h(0,this.a)
return s==null?new A.d():s},
$S:1}
A.lg.prototype={
$1(a){var s=this.a.$1(a),r=this.b.$1(a),q=s instanceof A.p
if(q&&r instanceof A.p)return A.v(B.c.a7(s.a,r.a))
else if(q&&r instanceof A.j)return new A.j(B.c.a7(s.a,r.a))
else{q=s instanceof A.j
if(q&&r instanceof A.p)return new A.j(B.h.a7(s.a,r.a))
else if(q&&r instanceof A.j)return new A.j(B.h.a7(s.a,r.a))}return new A.d()},
$S:1}
A.lh.prototype={
$1(a){return this.a.$1(a).aJ(this.b.$1(a))},
$S:1}
A.li.prototype={
$1(a){var s,r=this.a.$1(a),q=this.b.$1(a),p=r instanceof A.p
if(p&&q instanceof A.p)return r.a===q.a?$.U():$.T()
s=r instanceof A.j
if(s&&q instanceof A.j)return r.a===q.a?$.U():$.T()
if(p&&q instanceof A.j)return r.a===q.a?$.U():$.T()
if(s&&q instanceof A.p)return r.a===q.a?$.U():$.T()
if(r instanceof A.m&&q instanceof A.m)return r.a===q.a?$.U():$.T()
return r.A(0,q)===0?$.U():$.T()},
$S:3}
A.lj.prototype={
$1(a){var s,r=this.a.$1(a),q=this.b.$1(a),p=r instanceof A.p
if(p&&q instanceof A.p)return r.a!==q.a?$.U():$.T()
s=r instanceof A.j
if(s&&q instanceof A.j)return r.a!==q.a?$.U():$.T()
if(p&&q instanceof A.j)return r.a!==q.a?$.U():$.T()
if(s&&q instanceof A.p)return r.a!==q.a?$.U():$.T()
if(r instanceof A.m&&q instanceof A.m)return r.a!==q.a?$.U():$.T()
return r.A(0,q)!==0?$.U():$.T()},
$S:3}
A.lk.prototype={
$1(a){var s,r=this.a.$1(a),q=this.b.$1(a),p=r instanceof A.p
if(p&&q instanceof A.p)return r.a<q.a?$.U():$.T()
s=r instanceof A.j
if(s&&q instanceof A.j)return r.a<q.a?$.U():$.T()
if(p&&q instanceof A.j)return r.a<q.a?$.U():$.T()
if(s&&q instanceof A.p)return r.a<q.a?$.U():$.T()
return r.A(0,q)<0?$.U():$.T()},
$S:3}
A.ll.prototype={
$1(a){var s,r=this.a.$1(a),q=this.b.$1(a),p=r instanceof A.p
if(p&&q instanceof A.p)return r.a<=q.a?$.U():$.T()
s=r instanceof A.j
if(s&&q instanceof A.j)return r.a<=q.a?$.U():$.T()
if(p&&q instanceof A.j)return r.a<=q.a?$.U():$.T()
if(s&&q instanceof A.p)return r.a<=q.a?$.U():$.T()
return r.A(0,q)<=0?$.U():$.T()},
$S:3}
A.lm.prototype={
$1(a){var s,r=this.a.$1(a),q=this.b.$1(a),p=r instanceof A.p
if(p&&q instanceof A.p)return r.a>q.a?$.U():$.T()
s=r instanceof A.j
if(s&&q instanceof A.j)return r.a>q.a?$.U():$.T()
if(p&&q instanceof A.j)return r.a>q.a?$.U():$.T()
if(s&&q instanceof A.p)return r.a>q.a?$.U():$.T()
return r.A(0,q)>0?$.U():$.T()},
$S:3}
A.lo.prototype={
$1(a){var s,r=this.a.$1(a),q=this.b.$1(a),p=r instanceof A.p
if(p&&q instanceof A.p)return r.a>=q.a?$.U():$.T()
s=r instanceof A.j
if(s&&q instanceof A.j)return r.a>=q.a?$.U():$.T()
if(p&&q instanceof A.j)return r.a>=q.a?$.U():$.T()
if(s&&q instanceof A.p)return r.a>=q.a?$.U():$.T()
return r.A(0,q)>=0?$.U():$.T()},
$S:3}
A.lp.prototype={
$1(a){var s=J.x(this.b.$1(a)),r=J.x(this.c.$1(a)),q=this.a
if(r!==q.a){q.a=r
q.b=A.aI(r,!0)}q=q.b
if(q==null)q=null
else{q=q.b
q=q.test(s)}return q===!0?$.U():$.T()},
$S:3}
A.lq.prototype={
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
if(s.c==null&&!q&&!p&&!o&&!n){q=A.iv(r)
q=A.S(q,"\\%","%")
q=A.S(q,"\\_","_")
q=A.S(q,"%",".*")
s.c=A.aI("^"+A.S(q,"_",".")+"$",!1)}}}i=g.d.$1(a)
if(i instanceof A.d)return $.T()
h=A.qY(i.l(0))
s=g.a
if(s.r)return B.a.E(h,s.w)?$.U():$.T()
if(s.f)return B.a.U(h,s.w)?$.U():$.T()
if(s.e)return B.a.B(h,s.w)?$.U():$.T()
if(s.d)return h===s.w?$.U():$.T()
s=s.c.b
return s.test(h)?$.U():$.T()},
$S:3}
A.lr.prototype={
$1(a){return A.we(J.x(this.a.$1(a)),J.x(this.b.$1(a)))?$.U():$.T()},
$S:3}
A.ls.prototype={
$1(a){var s,r,q,p,o=this.a.$1(a),n=this.b.$1(a)
if(n instanceof A.aO){r=n.a
q=r.length
p=0
for(;;){if(!(p<r.length)){s=!1
break}if(o.A(0,r[p])===0){s=!0
break}r.length===q||(0,A.n)(r);++p}return A.v(s?1:0)}else return A.v(o.A(0,n)===0?1:0)},
$S:3}
A.lt.prototype={
$1(a){var s,r,q=this.a.$1(a),p=this.b.$1(a)
if(!(q instanceof A.p&&q.a===1))s=q instanceof A.j&&q.a>0
else s=!0
if(!(p instanceof A.p&&p.a===1))r=p instanceof A.j&&p.a>0
else r=!0
return s&&r?$.U():$.T()},
$S:3}
A.lu.prototype={
$1(a){var s,r,q=this.a.$1(a),p=this.b.$1(a)
if(!(q instanceof A.p&&q.a===1))s=q instanceof A.j&&q.a>0
else s=!0
if(!(p instanceof A.p&&p.a===1))r=p instanceof A.j&&p.a>0
else r=!0
return s||r?$.U():$.T()},
$S:3}
A.lv.prototype={
$1(a){return new A.d()},
$S:27}
A.lw.prototype={
$1(a){return new A.ig(A.c_(a.a),A.c_(a.b))},
$S:71}
A.lx.prototype={
$1(a){var s,r,q,p,o,n,m
for(s=this.a,r=s.length,q=0;q<s.length;s.length===r||(0,A.n)(s),++q){p=s[q]
o=p.a.$1(a)
n=!0
if(!(o instanceof A.p&&o.a===1))if(!(o instanceof A.j&&o.a>0)){m=o instanceof A.m&&o.a.toLowerCase()==="true"
n=m}if(n)return p.b.$1(a)}s=this.b
if(s!=null)return s.$1(a)
return new A.d()},
$S:1}
A.lz.prototype={
$1(a){var s,r,q,p=this.a.$1(a)
if(p instanceof A.d)return new A.d()
switch(this.b.a){case 0:if(p instanceof A.p)return p
if(p instanceof A.aG)return A.v(p.a?1:0)
s=A.a3(p.l(0),null)
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
case 6:return new A.bn(p.l(0))
case 7:q=A.bA(p.l(0))
return new A.bm(q==null?new A.aw(Date.now(),0,!1):q)
case 8:if(p instanceof A.b_)return p
return new A.b_(new Uint8Array(A.bx(B.x.aC(p.l(0)))))
case 3:case 4:return p}},
$S:1}
A.lA.prototype={
$1(a){return A.c_(a)},
$S:14}
A.lB.prototype={
$1(h2){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2,b3,b4,b5,b6,b7,b8,b9,c0,c1,c2,c3,c4,c5,c6,c7,c8,c9,d0,d1,d2,d3,d4,d5,d6,d7,d8,d9,e0,e1,e2,e3,e4,e5,e6,e7,e8,e9,f0,f1,f2,f3,f4,f5,f6,f7,f8,f9,g0,g1,g2,g3,g4,g5,g6,g7=this,g8=null,g9="0",h0="euclidean",h1=g7.a
if(h2.D(h1)){h1=h2.h(0,h1)
h1.toString
return h1}m=h1.toLowerCase()
if(h2.D(m)){h1=h2.h(0,m)
h1.toString
return h1}for(h1=h2.gZ(),h1=h1.gI(h1);h1.p();){l=h1.gF()
if(l.toLowerCase()===m){h1=h2.h(0,l)
h1.toString
return h1}}h1=g7.b
if(h1==="concat"){k=new A.cr("")
for(h1=g7.c,l=h1.length,j=0;j<h1.length;h1.length===l||(0,A.n)(h1),++j){i=h1[j].$1(h2)
if(!(i instanceof A.d)){h=i.l(0)
k.a+=h}}h1=k.a
return new A.m(h1.charCodeAt(0)==0?h1:h1)}if(h1==="concat_ws"&&g7.c.length>=2){h1=g7.c
g=J.x(h1[0].$1(h2))
k=new A.cr("")
for(f=!0,e=1;e<h1.length;++e){i=h1[e].$1(h2)
if(!(i instanceof A.d)){if(!f)k.a+=g
l=i.l(0)
k.a+=l
f=!1}}h1=k.a
return new A.m(h1.charCodeAt(0)==0?h1:h1)}if(h1==="length"||h1==="len"){h1=g7.c
if(h1.length===0)return new A.d()
i=B.b.ct(h1,h2)
return i instanceof A.d?new A.d():A.v(i.l(0).length)}if(h1==="upper"){h1=g7.c
if(h1.length===0)return new A.d()
i=B.b.ct(h1,h2)
return i instanceof A.d?new A.d():new A.m(i.l(0).toUpperCase())}if(h1==="lower"){h1=g7.c
if(h1.length===0)return new A.d()
i=B.b.ct(h1,h2)
return i instanceof A.d?new A.d():new A.m(i.l(0).toLowerCase())}if(h1==="trim"){h1=g7.c
if(h1.length===0)return new A.d()
i=B.b.ct(h1,h2)
return i instanceof A.d?new A.d():new A.m(B.a.W(i.l(0)))}if(h1==="substring"||h1==="substr"){h1=g7.c
if(h1.length===0)return new A.d()
d=J.x(h1[0].$1(h2))
l=d.length
if(l===0)return new A.m("")
c=h1.length>1?h1[1].$1(h2):A.v(1)
if(c instanceof A.p)h=c.a
else{h=A.a3(c.l(0),g8)
if(h==null)h=1}b=B.c.dt(h-1,0,l)
if(h1.length>2){a=h1[2].$1(h2)
if(a instanceof A.p)a0=a.a
else{h1=A.a3(a.l(0),g8)
a0=h1==null?l:h1}return new A.m(B.a.O(d,b,B.c.dt(b+a0,b,l)))}return new A.m(B.a.az(d,b))}if(h1==="coalesce"){for(h1=g7.c,l=h1.length,j=0;j<h1.length;h1.length===l||(0,A.n)(h1),++j){i=h1[j].$1(h2)
if(!(i instanceof A.d))return i}return new A.d()}if(h1==="nullif"&&g7.c.length>=2){h1=g7.c
a1=h1[0].$1(h2)
a2=h1[1].$1(h2)
if(a1.aw(0,a2)||a1.l(0)===a2.l(0))return new A.d()
return a1}if(h1==="greatest"){for(h1=g7.c,l=h1.length,a3=g8,j=0;j<h1.length;h1.length===l||(0,A.n)(h1),++j){i=h1[j].$1(h2)
if(!(i instanceof A.d))if(a3==null||i.A(0,a3)>0)a3=i}return a3==null?new A.d():a3}if(h1==="least"){for(h1=g7.c,l=h1.length,a4=g8,j=0;j<h1.length;h1.length===l||(0,A.n)(h1),++j){i=h1[j].$1(h2)
if(!(i instanceof A.d))if(a4==null||i.A(0,a4)<0)a4=i}return a4==null?new A.d():a4}if(h1==="typeof"&&g7.c.length!==0)return new A.m(g7.c[0].$1(h2).gae().b.toUpperCase())
if(h1==="now"||h1==="current_timestamp")return new A.bm(new A.aw(Date.now(),0,!1))
if(h1==="current_date"){a5=new A.aw(Date.now(),0,!1)
return new A.m(""+A.b1(a5)+"-"+B.a.a0(B.c.l(A.bB(a5)),2,g9)+"-"+B.a.a0(B.c.l(A.bI(a5)),2,g9))}if(h1==="gen_random_uuid"||h1==="uuid"){a6=J.dz(16,t.S)
for(a7=0;a7<16;++a7)a6[a7]=B.cw.cA(256)
a6[6]=a6[6]&15|64
a6[8]=a6[8]&63|128
a8=new A.h(a6,new A.l3(),A.z(a6).i("h<1,e>")).dE(0)
return new A.bn(B.a.O(a8,0,8)+"-"+B.a.O(a8,8,12)+"-"+B.a.O(a8,12,16)+"-"+B.a.O(a8,16,20)+"-"+B.a.az(a8,20))}if(h1==="generate_series"){h1=g7.c
l=A.z(h1).i("h<1,k>")
a9=A.r(new A.h(h1,new A.l4(h2),l),l.i("u.E"))
h1=a9.length!==0
if(h1&&a9[0] instanceof A.p)b0=t.A.a(a9[0]).a
else{l=A.a3(h1?a9[0].l(0):"1",g8)
b0=l==null?1:l}h1=a9.length>1
if(h1&&a9[1] instanceof A.p)b1=t.A.a(a9[1]).a
else{l=A.a3(h1?a9[1].l(0):"10",g8)
b1=l==null?10:l}h1=a9.length>2
if(h1&&a9[2] instanceof A.p)b2=t.A.a(a9[2]).a
else{l=A.a3(h1?a9[2].l(0):"1",g8)
b2=l==null?1:l}b3=A.a([],t.K)
if(b2>0)for(e=b0;e<=b1;e+=b2)b3.push(A.v(e))
else if(b2<0)for(e=b0;e>=b1;e+=b2)b3.push(A.v(e))
return new A.aO(b3)}if(h1==="ifnull"||h1==="nvl"){h1=g7.c
if(h1.length<2)return new A.d()
a1=h1[0].$1(h2)
return!(a1 instanceof A.d)?a1:h1[1].$1(h2)}if(h1==="date"){h1=g7.c
a5=A.bA(h1.length===0?new A.aw(Date.now(),0,!1).bs():J.x(h1[0].$1(h2)))
if(a5==null)a5=new A.aw(Date.now(),0,!1)
return new A.m(""+A.b1(a5)+"-"+B.a.a0(B.c.l(A.bB(a5)),2,g9)+"-"+B.a.a0(B.c.l(A.bI(a5)),2,g9))}if(h1==="time"){h1=g7.c
a5=A.bA(h1.length===0?new A.aw(Date.now(),0,!1).bs():J.x(h1[0].$1(h2)))
if(a5==null)a5=new A.aw(Date.now(),0,!1)
return new A.m(B.a.a0(B.c.l(A.dN(a5)),2,g9)+":"+B.a.a0(B.c.l(A.eT(a5)),2,g9)+":"+B.a.a0(B.c.l(A.eU(a5)),2,g9))}if(h1==="datetime"){h1=g7.c
b4=h1.length===0?g8:J.x(h1[0].$1(h2))
if(b4!=null&&b4!=="now"){h1=A.bA(b4)
a5=h1==null?new A.aw(Date.now(),0,!1):h1}else a5=new A.aw(Date.now(),0,!1)
return new A.m(""+A.b1(a5)+"-"+B.a.a0(B.c.l(A.bB(a5)),2,g9)+"-"+B.a.a0(B.c.l(A.bI(a5)),2,g9)+" "+B.a.a0(B.c.l(A.dN(a5)),2,g9)+":"+B.a.a0(B.c.l(A.eT(a5)),2,g9)+":"+B.a.a0(B.c.l(A.eU(a5)),2,g9))}if(h1==="abs"&&g7.c.length!==0){i=g7.c[0].$1(h2)
if(i instanceof A.p)return A.v(Math.abs(i.a))
if(i instanceof A.j)return new A.j(Math.abs(i.a))
if(i instanceof A.a8)return new A.a8(Math.abs(i.a))
b5=A.ra(i.l(0))
if(b5==null)b5=0
return A.fQ(b5)?A.v(Math.abs(b5)):new A.j(Math.abs(b5))}if(h1==="round"&&g7.c.length!==0){h1=g7.c
i=h1[0].$1(h2)
if(h1.length>1){h1=A.a3(J.x(h1[1].$1(h2)),g8)
b6=h1==null?0:h1}else b6=0
b7=A.aH(i.l(0))
if(b7==null)b7=0
if(b6===0)return A.v(B.h.fv(b7))
b8=Math.pow(10,b6)
return new A.j(B.h.fv(b7*b8)/b8)}if((h1==="ceil"||h1==="ceiling")&&g7.c.length!==0){b7=A.aH(J.x(g7.c[0].$1(h2)))
return A.v(B.h.iy(b7==null?0:b7))}if(h1==="floor"&&g7.c.length!==0){b7=A.aH(J.x(g7.c[0].$1(h2)))
return A.v(B.h.dA(b7==null?0:b7))}if((h1==="power"||h1==="pow")&&g7.c.length>=2){h1=g7.c
b9=A.aH(J.x(h1[0].$1(h2)))
if(b9==null)b9=0
c0=A.aH(J.x(h1[1].$1(h2)))
if(c0==null)c0=0
return new A.j(Math.pow(b9,c0))}if(h1==="sqrt"&&g7.c.length!==0){b7=A.aH(J.x(g7.c[0].$1(h2)))
if(b7==null)b7=0
return new A.j(Math.sqrt(b7))}if(h1==="mod"&&g7.c.length>=2){h1=g7.c
c1=A.a3(J.x(h1[0].$1(h2)),g8)
if(c1==null)c1=0
c2=A.a3(J.x(h1[1].$1(h2)),g8)
return A.v(B.c.a7(c1,c2==null?1:c2))}if(h1==="sign"&&g7.c.length!==0){b7=A.aH(J.x(g7.c[0].$1(h2)))
if(b7==null)b7=0
if(b7>0)return A.v(1)
if(b7<0)return A.v(-1)
return A.v(0)}if(h1==="replace"&&g7.c.length>=3){h1=g7.c
d=J.x(h1[0].$1(h2))
c3=J.x(h1[1].$1(h2))
c4=J.x(h1[2].$1(h2))
return new A.m(A.S(d,c3,c4))}if(h1==="lpad"&&g7.c.length>=2){h1=g7.c
d=J.x(h1[0].$1(h2))
c5=A.a3(J.x(h1[1].$1(h2)),g8)
if(c5==null)c5=d.length
return new A.m(B.a.a0(d,c5,h1.length>2?J.x(h1[2].$1(h2)):" "))}if(h1==="rpad"&&g7.c.length>=2){h1=g7.c
d=J.x(h1[0].$1(h2))
c5=A.a3(J.x(h1[1].$1(h2)),g8)
if(c5==null)c5=d.length
return new A.m(B.a.j2(d,c5,h1.length>2?J.x(h1[2].$1(h2)):" "))}if(h1==="reverse"&&g7.c.length!==0)return new A.m(new A.f0(A.a(J.x(g7.c[0].$1(h2)).split(""),t.s),t.bJ).dE(0))
if(h1==="regexp_like"&&g7.c.length>=2){h1=g7.c
d=J.x(h1[0].$1(h2))
h1=A.aI(J.x(h1[1].$1(h2)),!0)
return new A.aG(h1.b.test(d))}if(h1==="split_part"&&g7.c.length>=3){h1=g7.c
d=J.x(h1[0].$1(h2))
c6=J.x(h1[1].$1(h2))
h1=A.a3(J.x(h1[2].$1(h2)),g8)
c7=(h1==null?1:h1)-1
c8=d.split(c6)
if(c7>=0&&c7<c8.length)return new A.m(c8[c7])
return new A.m("")}if(h1==="initcap"&&g7.c.length!==0)return new A.m(new A.h(A.a(J.x(g7.c[0].$1(h2)).split(" "),t.s),new A.l5(),t.e).S(0," "))
if(h1==="date_add"&&g7.c.length>=2){h1=g7.c
b4=J.x(h1[0].$1(h2))
c9=A.a3(J.x(h1[1].$1(h2)),g8)
if(c9==null)c9=0
a5=A.bA(b4)
if(a5==null)a5=new A.aw(Date.now(),0,!1)
d0=a5.dX(A.j2(c9,0).a)
return new A.m(""+A.b1(d0)+"-"+B.a.a0(B.c.l(A.bB(d0)),2,g9)+"-"+B.a.a0(B.c.l(A.bI(d0)),2,g9))}if(h1==="date_sub"&&g7.c.length>=2){h1=g7.c
b4=J.x(h1[0].$1(h2))
c9=A.a3(J.x(h1[1].$1(h2)),g8)
if(c9==null)c9=0
a5=A.bA(b4)
if(a5==null)a5=new A.aw(Date.now(),0,!1)
d1=a5.dX(0-A.j2(c9,0).a)
return new A.m(""+A.b1(d1)+"-"+B.a.a0(B.c.l(A.bB(d1)),2,g9)+"-"+B.a.a0(B.c.l(A.bI(d1)),2,g9))}if(h1==="date_trunc"&&g7.c.length>=2){h1=g7.c
d2=J.x(h1[0].$1(h2)).toLowerCase()
a5=A.bA(J.x(h1[1].$1(h2)))
if(a5==null)a5=new A.aw(Date.now(),0,!1)
if(d2==="year")return new A.m(""+A.b1(a5)+"-01-01 00:00:00")
if(d2==="month")return new A.m(""+A.b1(a5)+"-"+B.a.a0(B.c.l(A.bB(a5)),2,g9)+"-01 00:00:00")
if(d2==="day")return new A.m(""+A.b1(a5)+"-"+B.a.a0(B.c.l(A.bB(a5)),2,g9)+"-"+B.a.a0(B.c.l(A.bI(a5)),2,g9)+" 00:00:00")
if(d2==="hour")return new A.m(""+A.b1(a5)+"-"+B.a.a0(B.c.l(A.bB(a5)),2,g9)+"-"+B.a.a0(B.c.l(A.bI(a5)),2,g9)+" "+B.a.a0(B.c.l(A.dN(a5)),2,g9)+":00:00")
return new A.m(a5.bs())}if(h1==="extract"&&g7.c.length>=2){h1=g7.c
d3=J.x(h1[0].$1(h2)).toLowerCase()
a5=A.bA(J.x(h1[1].$1(h2)))
if(a5==null)a5=new A.aw(Date.now(),0,!1)
if(d3==="year")return A.v(A.b1(a5))
if(d3==="month")return A.v(A.bB(a5))
if(d3==="day")return A.v(A.bI(a5))
if(d3==="hour")return A.v(A.dN(a5))
if(d3==="minute")return A.v(A.eT(a5))
if(d3==="second")return A.v(A.eU(a5))
return A.v(0)}if(h1==="json_array"){h1=g7.c
l=A.z(h1).i("h<1,e>")
d4=A.r(new A.h(h1,new A.l6(h2),l),l.i("u.E"))
return new A.L(d4,g8)}if(h1==="json_object"){d5=A.o(t.N,t.z)
for(h1=g7.c,e=0;e<h1.length-1;e+=2){d6=J.x(h1[e].$1(h2))
i=h1[e+1].$1(h2)
if(i instanceof A.p)l=i.a
else l=i instanceof A.j?i.a:i.l(0)
d5.k(0,d6,l)}return new A.L(d5,g8)}if(h1==="version")return new A.m("ULTSQL v1.0.12 (Pure-Dart Converged Database Engine)")
if((h1==="position"||h1==="strpos")&&g7.c.length>=2){h1=g7.c
d7=J.x(h1[0].$1(h2))
d8=B.a.ad(J.x(h1[1].$1(h2)),d7)
return A.v(d8===-1?0:d8+1)}if(h1==="strftime"){h1=g7.c
if(h1.length<2)return new A.d()
d9=J.x(h1[0].$1(h2))
b4=J.x(h1[1].$1(h2))
if(b4==="now")a5=new A.aw(Date.now(),0,!1)
else{h1=A.bA(b4)
a5=h1==null?new A.aw(Date.now(),0,!1):h1}h1=B.c.l(A.b1(a5))
h1=A.S(d9,"%Y",h1)
l=B.a.a0(B.c.l(A.bB(a5)),2,g9)
h1=A.S(h1,"%m",l)
l=B.a.a0(B.c.l(A.bI(a5)),2,g9)
h1=A.S(h1,"%d",l)
l=B.a.a0(B.c.l(A.dN(a5)),2,g9)
h1=A.S(h1,"%H",l)
l=B.a.a0(B.c.l(A.eT(a5)),2,g9)
h1=A.S(h1,"%M",l)
l=B.a.a0(B.c.l(A.eU(a5)),2,g9)
return new A.m(A.S(h1,"%S",l))}if(h1==="in_list"){h1=g7.c
l=A.z(h1).i("h<1,k>")
a9=A.r(new A.h(h1,new A.l7(h2),l),l.i("u.E"))
return new A.aO(a9)}if(h1==="st_point"&&g7.c.length===2){h1=g7.c
e0=h1[0].$1(h2)
e1=h1[1].$1(h2)
if(e0 instanceof A.j)e2=e0.a
else e2=e0 instanceof A.p?e0.a:0
if(e1 instanceof A.j)e3=e1.a
else e3=e1 instanceof A.p?e1.a:0
return new A.m("POINT("+A.D(e2)+" "+A.D(e3)+")")}if(h1==="st_distance"&&g7.c.length===2){h1=g7.c
e4=h1[0].$1(h2)
e5=h1[1].$1(h2)
if(e4 instanceof A.m&&e5 instanceof A.m){e6=A.oS(e4.a)
e7=A.oS(e5.a)
if(e6!=null&&e7!=null)return new A.j(Math.sqrt(Math.pow(e6[0]-e7[0],2)+Math.pow(e6[1]-e7[1],2)))}return new A.d()}if(h1==="st_contains"&&g7.c.length===2){h1=g7.c
e8=h1[0].$1(h2)
e9=h1[1].$1(h2)
if(e8 instanceof A.m&&e9 instanceof A.m){f0=A.tq(e8.a)
f1=A.oS(e9.a)
if(f0!=null&&f1!=null){for(f2=f0.length-1,f3=!1,e=0;e<f0.length;f4=e+1,f2=e,e=f4)if(J.a_(f0[e],1)>f1[1]!==J.a_(f0[f2],1)>f1[1]&&f1[0]<(J.a_(f0[f2],0)-J.a_(f0[e],0))*(f1[1]-J.a_(f0[e],1))/(J.a_(f0[f2],1)-J.a_(f0[e],1))+J.a_(f0[e],0))f3=!f3
return A.v(f3?1:0)}}return new A.d()}l=$.cN
if(l!=null){s=l
l=s.a.b
l===$&&A.b()
r=l.y.h(0,h1.toLowerCase())
if(r!=null){h1=g7.c
l=A.z(h1).i("h<1,k>")
a9=A.r(new A.h(h1,new A.l8(h2),l),l.i("u.E"))
q=A.Z(s.c,t.N,t.r)
s.c.v(0)
e=0
for(;;){h1=r.c
h1===$&&A.b()
if(!(e<h1.length))break
h1=r.c
h1===$&&A.b()
f5=h1[e]
f6=e<a9.length?a9[e]:new A.d()
s.c.k(0,f5.a,f6);++e}p=new A.d()
try{h1=r.e
h1===$&&A.b()
l=h1.length
j=0
for(;j<h1.length;h1.length===l||(0,A.n)(h1),++j){o=h1[j]
s.aB(o)}}catch(f7){h1=A.aU(f7)
if(h1 instanceof A.dQ){n=h1
p=n.a}else throw f7}finally{s.c.v(0)
s.c.X(0,q)}return p}}if(h1==="time_bucket"&&g7.c.length===2){h1=g7.c
f8=h1[0].$1(h2)
f9=h1[1].$1(h2)
if(f8 instanceof A.m&&f9 instanceof A.m){g0=f8.a
a5=A.bA(f9.a)
if(a5!=null){if(B.a.B(g0,"m")){h1=A.a3(A.S(g0,"m",""),g8)
g1=(h1==null?0:h1)*60*1000}else if(B.a.B(g0,"h")){h1=A.a3(A.S(g0,"h",""),g8)
g1=(h1==null?0:h1)*60*60*1000}else if(B.a.B(g0,"s")){h1=A.a3(A.S(g0,"s",""),g8)
g1=(h1==null?0:h1)*1000}else g1=0
if(g1>0){h1=B.c.aY(a5.a,g1)
l=a5.c
return new A.m(new A.aw(A.oE(h1*g1,0,l),0,l).bs())}}}return new A.d()}if(h1==="vector_distance"){l=g7.c.length
l=l===2||l===3}else l=!1
if(l){h1=g7.c
a1=h1[0].$1(h2)
a2=h1[1].$1(h2)
if(h1.length===3){g2=h1[2].$1(h2)
g3=g2 instanceof A.m?g2.a.toLowerCase():h0}else g3=h0
if(a1 instanceof A.m){g4=A.q2(a1.a)
a1=g4==null?a1:g4}if(a2 instanceof A.m){g5=A.q2(a2.a)
a2=g5==null?a2:g5}if(a1 instanceof A.a5&&a2 instanceof A.a5)switch(g3){case"cosine":return new A.j(a1.cl(a2))
case"dot":return new A.j(a1.cn(a2))
case"euclidean":default:return new A.j(a1.cm(a2))}return new A.d()}if(h1==="cast"&&g7.c.length===2){b4=g7.c[0].$1(h2)
g6=J.x(t.gV.a(g7.d.c[1]).b)
if(b4 instanceof A.d)return new A.d()
if(g6==="DataType.text")return new A.m(b4.l(0))
else if(g6==="DataType.integer"){if(b4 instanceof A.p)return b4
if(b4 instanceof A.j)return A.v(B.h.be(b4.a))
h1=A.a3(b4.l(0),g8)
return A.v(h1==null?0:h1)}else if(g6==="DataType.double"){if(b4 instanceof A.j)return b4
if(b4 instanceof A.p)return new A.j(b4.a)
h1=A.aH(b4.l(0))
return new A.j(h1==null?0:h1)}return new A.d()}if(h1==="json_set"&&g7.c.length===3){h1=g7.c
return A.r4(h1[0].$1(h2),h1[1].$1(h2),h1[2].$1(h2))}if(h1==="json_remove"&&g7.c.length===2){h1=g7.c
return A.r3(h1[0].$1(h2),h1[1].$1(h2))}return new A.d()},
$S:1}
A.l3.prototype={
$1(a){return B.a.a0(B.c.fA(a,16),2,"0")},
$S:5}
A.l4.prototype={
$1(a){return a.$1(this.a)},
$S:28}
A.l5.prototype={
$1(a){return a.length===0?"":a[0].toUpperCase()+B.a.az(a,1).toLowerCase()},
$S:7}
A.l6.prototype={
$1(a){return J.x(a.$1(this.a))},
$S:37}
A.l7.prototype={
$1(a){return a.$1(this.a)},
$S:28}
A.l8.prototype={
$1(a){return a.$1(this.a)},
$S:28}
A.lC.prototype={
$1(a){return new A.d()},
$S:27}
A.lK.prototype={
$1(a){return A.cA(B.a.W(a))},
$S:9}
A.lJ.prototype={
$1(a){var s=J.X(a)
return A.a([A.ir(s.h(a,0)),A.ir(s.h(a,1))],t.n)},
$S:75}
A.mg.prototype={}
A.oq.prototype={
$0(){return A.oA(this.a)},
$S:26}
A.or.prototype={
$0(){return A.oA(this.a)},
$S:26}
A.dK.prototype={
N(){this.z=0},
cr(){var s=0,r=A.b5(t.H),q,p=this,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2,b3,b4
var $async$cr=A.b6(function(b5,b6){if(b5===1)return A.b2(b6,r)
for(;;)switch(s){case 0:b4=p.f
if(b4===0){p.y=A.a([],t.b)
s=1
break}o=A.a([],t.dL)
for(n=p.r,m=t.c,l=p.w,k=l==null,j=p.a,i=p.c,h=p.b,g=p.d,f=p.e,e=p.x,d=e!=null,c=0;B.c.cN(c,n);){b=B.c.aY(b4,n)
a=c<B.c.a7(b4,n)?c:B.c.a7(b4,n)
a0=c*b+a;++c
a=B.c.aY(b4,n)
b=c<B.c.a7(b4,n)?c:B.c.a7(b4,n)
a1=c*a+b
if(a0>=a1)continue
a2=new A.mg(j,a0,a1,i,h,g,f,l,e)
if(!k||d)o.push(A.pY(new A.md(a2),m))
else o.push(A.pY(new A.me(a2),m))}s=3
return A.as(A.te(o,m),$async$cr)
case 3:a3=b6
b4=!k||d
n=t.b_
if(b4){b4=t.r
a4=A.o(b4,n)
for(n=J.au(a3),m=t.eM,l=t.A,k=t.N;n.p();)for(j=J.au(n.gF());j.p();){i=j.gF()
h=i.h(0,"group_key")
h.toString
if(!a4.D(h))a4.k(0,h,A.Z(i,k,b4))
else{h=a4.h(0,h)
h.toString
for(g=e.length,a5=0;a5<e.length;e.length===g||(0,A.n)(e),++a5){a6=e[a5]
a7=a6.b
if(a7==null)a7=A.R(a6.a)
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
h.k(0,a7,f)}else if(b)h.k(0,a7,d)}}}}}for(b4=a4.$ti,n=new A.an(a4,a4.r,a4.e,b4.i("an<2>"));n.p();){k=n.d
k.T(0,"group_key")
for(j=e.length,a5=0;a5<e.length;e.length===j||(0,A.n)(e),++a5){a6=e[a5]
a8=a6.a
if(a8 instanceof A.af&&a8.b.toLowerCase()==="avg"){a7=a6.b
if(a7==null)a7=A.R(a8)
b3=m.a(k.h(0,a7))
i=a7+"_count"
h=l.a(k.h(0,i)).a
k.k(0,a7,h>0?new A.j(b3.a/h):new A.d())
k.T(0,i)}}}b4=b4.i("b0<2>")
b4=A.r(new A.b0(a4,b4),b4.i("F.E"))
p.y=b4}else{b4=J.rO(a3,new A.mf(),n)
b4=A.r(b4,b4.$ti.i("F.E"))
p.y=b4}case 1:return A.b3(q,r)}})
return A.b4($async$cr,r)},
K(){var s,r=this.y
if(r==null)throw A.c(A.fg("ParallelScanNode not executed. Call executeParallelScan() first."))
s=this.z
if(s>=r.length)return null
this.z=s+1
return r[s]},
L(){this.y=null},
G(a){return B.a.P("  ",a)+"ParallelScanNode(table: "+this.b.a+", workers: "+A.D(this.r)+")"},
a6(){return this.G(0)}}
A.md.prototype={
$0(){return A.wg(this.a)},
$S:15}
A.me.prototype={
$0(){return A.wh(this.a)},
$S:15}
A.mf.prototype={
$1(a){return a},
$S:78}
A.P.prototype={}
A.oe.prototype={
$1(a){var s=J.X(a)
return s.gaa(a)?t.r.a(s.h(a,0)):new A.d()},
$S:52}
A.of.prototype={
$1(a){return A.bO(a,this.a)},
$S:19}
A.f4.prototype={
fU(a,b,c,d){var s,r,q,p,o,n,m=this
m.f!==$&&A.bc()
s=m.f=m.c
r=A.z(s).i("h<1,e>")
r=A.r(new A.h(s,new A.mK(m),r),r.i("u.E"))
m.r!==$&&A.bc()
m.r=r
q=A.z(s).i("h<1,e>")
q=A.r(new A.h(s,new A.mL(m),q),q.i("u.E"))
m.w!==$&&A.bc()
m.w=q
m.x!==$&&A.bc()
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
r.e=q.c1(n,r.d,m,r.b.b.length,s,p.ax)},
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
A.mK.prototype={
$1(a){var s=this.a.b
return s.a+"."+s.b[a]},
$S:5}
A.mL.prototype={
$1(a){return this.a.b.b[a]},
$S:5}
A.dU.prototype={
N(){this.a.N()},
K(){var s,r,q,p,o,n,m,l=this.a.K()
if(l==null)return null
s=A.o(t.N,t.r)
for(r=l.gbY(),r=r.gI(r),q=this.b,p=q!=null;r.p();){o=r.gF()
n=o.a
o=o.b
s.k(0,n,o)
m=B.b.gV(n.split("."))
s.k(0,m,o)
if(p)s.k(0,q.toLowerCase()+"."+m,o)}return s},
L(){this.a.L()},
G(a){var s=B.a.P("  ",a),r=this.b,q=r!=null?" AS "+r:""
return s+"SubqueryScanNode"+q+"\n"+this.a.G(a+1)},
a6(){return this.G(0)}}
A.hj.prototype={
N(){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1=this
a1.d=0
a1.c=A.a([],t.b)
if($.cN==null)return
p=a1.a
o=t.N
n=t.r
s=A.bO(p,A.o(o,n))
r=[]
if(s instanceof A.aO)r=s.a
else if(s instanceof A.L){m=t.j
if(m.b(s.ga2()))r=m.a(s.ga2())}else if(s instanceof A.m)try{q=B.o.ag(s.a)
if(t.j.b(q))r=q}catch(l){}for(m=J.au(r),p=p.b,k=a1.b,j=k!=null,i=t.j,h=t.f;m.p();){g=m.gF()
f=A.o(o,n)
if(h.b(g))g.a1(0,new A.jd(a1,f))
else if(i.b(g))for(e=J.X(g),d=0;d<e.gt(g);++d){c="col"+d
b=A.cg(e.h(g,d))
f.k(0,c,b)
if(j)f.k(0,k.toLowerCase()+"."+c,b)
else f.k(0,p.toLowerCase()+"."+c,b)}else{e=g instanceof A.L
if(e){a=g.a
a=h.b(a==null?g.a=B.o.ag(g.gaP()):a)}else a=!1
if(a){e=g.a
h.a(e==null?g.a=B.o.ag(g.gaP()):e).a1(0,new A.je(a1,f))}else if(g instanceof A.aO)for(e=g.a,d=0;d<e.length;++d){c="col"+d
b=e[d]
f.k(0,c,b)
if(j)f.k(0,k.toLowerCase()+"."+c,b)
else f.k(0,p.toLowerCase()+"."+c,b)}else{if(e){e=g.a
e=i.b(e==null?g.a=B.o.ag(g.gaP()):e)}else e=!1
if(e){e=g.a
a0=i.a(e==null?g.a=B.o.ag(g.gaP()):e)
for(e=J.X(a0),d=0;d<e.gt(a0);++d){c="col"+d
b=A.cg(e.h(a0,d))
f.k(0,c,b)
if(j)f.k(0,k.toLowerCase()+"."+c,b)
else f.k(0,p.toLowerCase()+"."+c,b)}}else{b=g instanceof A.k?g:A.cg(g)
f.k(0,"value",b)
if(j)f.k(0,k.toLowerCase()+".value",b)
else f.k(0,p.toLowerCase()+".value",b)}}}a1.c.push(f)}},
K(){var s=this.c
if(s==null||this.d>=s.length)return null
return s[this.d++]},
L(){this.c=null},
G(a){var s=B.a.P("  ",a),r=this.b,q=r!=null?" AS "+r:""
return s+"FunctionScanNode("+A.R(this.a)+q+")"},
a6(){return this.G(0)}}
A.jd.prototype={
$2(a,b){var s,r,q=J.x(a),p=A.cg(b),o=this.b
o.k(0,q,p)
s=this.a
r=s.b
if(r!=null)o.k(0,r.toLowerCase()+"."+q,p)
else o.k(0,s.a.b.toLowerCase()+"."+q,p)},
$S:4}
A.je.prototype={
$2(a,b){var s,r,q=J.x(a),p=A.cg(b),o=this.b
o.k(0,q,p)
s=this.a
r=s.b
if(r!=null)o.k(0,r.toLowerCase()+"."+q,p)
else o.k(0,s.a.b.toLowerCase()+"."+q,p)},
$S:4}
A.hf.prototype={
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
A.h4.prototype={
fR(a,b,c){var s=this,r=s.c,q=A.z(r).i("h<1,e>"),p=q.i("u.E"),o=A.r(new A.h(r,new A.iS(s),q),p)
s.f!==$&&A.bc()
s.f=o
r=A.r(new A.h(r,new A.iT(s),q),p)
s.r!==$&&A.bc()
s.r=r},
N(){var s,r,q,p,o,n=this,m=n.d
B.b.v(m)
for(s=n.c,r=s.length,q=n.a,p=0;p<s.length;s.length===r||(0,A.n)(s),++p){o=q.cO(s[p])
m.push(new A.ca(o.a(),o.$ti.i("ca<1>")))}s=m.length
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
return B.a.P("  ",a)+"ColumnScanNode(table: "+this.b.a+", columns: ["+new A.h(s,new A.iU(this),A.z(s).i("h<1,e>")).S(0,", ")+"])"},
a6(){return this.G(0)}}
A.iS.prototype={
$1(a){var s=this.a.b
return s.a+"."+s.b[a]},
$S:5}
A.iT.prototype={
$1(a){return this.a.b.b[a]},
$S:5}
A.iU.prototype={
$1(a){return this.a.b.b[a]},
$S:5}
A.eA.prototype={
fS(a,b,c,d,e,f){var s,r,q=this,p=q.f,o=A.z(p).i("h<1,e>"),n=o.i("u.E"),m=A.r(new A.h(p,new A.jL(q),o),n)
q.Q!==$&&A.bc()
q.Q=m
o=A.r(new A.h(p,new A.jM(q),o),n)
q.as!==$&&A.bc()
q.as=o
q.at!==$&&A.bc()
n=q.at=A.o(t.N,t.S)
for(s=0;s<p.length;++s){r=p[s]
n.k(0,m[s],r)
n.k(0,o[s],r)}p=A.a9(q.b.b.length,new A.d(),!1,t.r)
q.ax!==$&&A.bc()
q.ax=p},
fG(){var s,r,q,p=this,o=new A.bK()
$.cC()
o.b7()
s=p.a.a
r=s.ga5()
q=s.ax
if(r!=null&&r.a!==0)if(q.b.h(0,r.a)===B.au)return null
if(new A.fm(A.oV(q.c,t.S),t.dC).gt(0)!==0)return null
s=p.z
if(s!=null)return s
s=p.r
if(s!=null)return s.length
s=p.c
s.ap()
p.z=s.iz(p.d,p.e)
if(o.b==null)o.b=$.bs.$0()
A.cd("--> TIME: IndexScanNode.getFastCount took: "+o.gbB()+"us, count="+A.D(p.z))
return p.z},
N(){var s=this
s.r=s.z=null
s.w=0
s.y=s.x=null},
hR(a,b,c){var s,r,q,p,o,n,m
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
return q.ax.aD(s,r,n,m)},
hP(a,b,c,d){if(c<12)return A.qh(b,0,c,d)
return A.qh(b,12,c-12,d)},
K(){var s,r,q,p,o,n,m,l,k,j,i=this
if(i.r==null){s=i.c
s.ap()
s=i.r=s.cQ(i.d,i.e)
if(i.f.length!==0&&s.length>250)B.b.ar(s,new A.jN())}for(s=i.a,r=s.a,q=s.c+"/"+s.b+".db";p=i.w,o=i.r,p<o.length;){i.w=p+1
n=o[p]
p=i.y
o=n.a
if(p!==o){if(i.x!=null){p.toString
r.u(q,p,!1)}i.x=r.C(q,o)
i.y=o}p=i.x
p.toString
m=A.ab(p,n.b)
if(m!=null){l=A.aq(m,0,null)
p=m.length
if(i.hR(s,l,p)){r=i.ax
r===$&&A.b()
B.b.bD(r,0,r.length,new A.d())
for(q=i.f,k=0;k<q.length;++k){j=q[k]
r[j]=i.hP(s,l,p,j)}s=i.at
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
G(a){var s,r=this,q=B.a.P("  ",a),p=B.b.gV(r.c.b.split("/")),o=A.S(p,".idx","")
p=r.d
p=A.D(p==null?"-\u221e":p)
s=r.e
return q+"IndexScanNode(table: "+r.b.a+", index: "+o+", range: ["+p+", "+A.D(s==null?"\u221e":s)+"])"},
a6(){return this.G(0)}}
A.jL.prototype={
$1(a){var s=this.a.b
return s.a+"."+s.b[a]},
$S:5}
A.jM.prototype={
$1(a){return this.a.b.b[a]},
$S:5}
A.jN.prototype={
$2(a,b){var s=B.c.A(a.a,b.a)
if(s!==0)return s
return B.c.A(a.b,b.b)},
$S:32}
A.ci.prototype={
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
return s+"FilterNode(condition: "+A.R(this.b)+")\n"+r},
a6(){return this.G(0)},
d9(a){return this.gd8().$1(a)}}
A.co.prototype={
fT(a,b){var s=this.b,r=A.z(s).i("h<1,k(w<e,k>)>")
s=A.r(new A.h(s,new A.mm(),r),r.i("u.E"))
this.c!==$&&A.bc()
this.c=s},
N(){return this.a.N()},
K(){var s,r,q,p,o,n,m,l,k=this.a.K()
if(k==null)return null
s=A.o(t.N,t.r)
for(r=this.b,q=0;q<r.length;++q){p=r[q]
o=p.a
n=o instanceof A.I
if(n&&B.b.gH(o.b)==="*"){s.X(0,k)
continue}m=this.c
m===$&&A.b()
l=m[q].$1(k)
m=p.b
if(m!=null)s.k(0,m,l)
else if(n)s.k(0,B.b.S(o.b,"."),l)
else s.k(0,A.R(o),l)}return s},
L(){return this.a.L()},
G(a){var s=B.a.P("  ",a),r=this.a.G(a+1),q=this.b
return s+"ProjectNode(projections: ["+new A.h(q,new A.mn(),A.z(q).i("h<1,e>")).S(0,", ")+"])\n"+r},
a6(){return this.G(0)}}
A.mm.prototype={
$1(a){return A.K(a.a)},
$S:79}
A.mn.prototype={
$1(a){var s=a.b
return s==null?A.R(a.a):s},
$S:40}
A.da.prototype={
dM(a0,a1,a2){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a=this
for(s=a1.length,r=a.x,q=a.w,p=a.r,o=a.e,n=a.f,m=a.d,l=a.c,k=a.b,j=0;j<a1.length;a1.length===s||(0,A.n)(a1),++j){i=a1[j]
h=i.a
g=i.b
if(g==null)g=A.R(h)
if(h instanceof A.af){f=h.b.toLowerCase()
if(f==="count"){e=h.c
if(e.length!==0){e=e[0]
e=e instanceof A.I&&B.b.gH(e.b)==="*"}else e=!0
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
iH(a0){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b=this,a=A.o(t.N,t.r)
for(s=a0.length,r=b.x,q=b.w,p=b.r,o=b.f,n=b.e,m=b.d,l=b.c,k=b.b,j=0;j<a0.length;a0.length===s||(0,A.n)(a0),++j){i=a0[j]
h=i.a
g=i.b
if(g==null)g=A.R(h)
if(h instanceof A.af){f=h.b.toLowerCase()
if(f==="count"){e=k.h(0,g)
a.k(0,g,A.v(e==null?0:e))}else if(f==="sum"){d=l.h(0,g)
if(d==null)a.k(0,g,new A.d())
else{e=m.h(0,g)
a.k(0,g,e===!0?new A.j(d):A.v(B.h.be(d)))}}else if(f==="avg"){c=n.h(0,g)
if(c==null)c=0
d=o.h(0,g)
if(d==null)d=0
a.k(0,g,c>0?new A.j(d/c):new A.d())}else if(f==="min"){e=p.h(0,g)
a.k(0,g,e==null?new A.d():e)}else if(f==="max"){e=q.h(0,g)
a.k(0,g,e==null?new A.d():e)}else{e=r.h(0,g)
a.k(0,g,e==null?new A.d():e)}}else{e=r.h(0,g)
a.k(0,g,e==null?new A.d():e)}}return a}}
A.bY.prototype={
N(){this.a.N()
this.e=null
this.f=0},
i8(){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2,b3,b4,b5,b6,b7,b8,b9,c0,c1,c2,c3,c4,c5,c6,c7,c8,c9,d0,d1,d2,d3,d4,d5=this,d6=null,d7={},d8=d5.b,d9=d8 instanceof A.ag
if(d9){s=d5.c
s=s.length===1&&s[0].a instanceof A.af}else s=!1
if(s){s=d5.c
r=t.du.a(s[0].a)
if(r.b.toLowerCase()==="count"){q=r.c
p=q.length
o=!0
if(p!==0)if(p===1){p=q[0]
if(!(p instanceof A.I&&B.b.gH(p.b)==="*")){q=q[0]
q=q instanceof A.ag&&B.a.E(J.x(q.b),"*")}else q=o
o=q}else o=!1
if(o){n=d5.a
m=n
l=!1
for(;;){d8=m instanceof A.ci
if(!(d8||m instanceof A.co))break
if(d8){m=m.a
l=!0}else if(m instanceof A.co)m=m.a}if(m instanceof A.eA&&!l){k=m.fG()
j=k!=null
i=j?k:0}else{i=0
j=!1
if(m instanceof A.f4&&!l){h=$.cN
if(h!=null){d8=h.a.b
d8===$&&A.b()
i=d8.aX(m.b.a).a
j=i>0
i=j?i:0}}}if(!j)for(;;){if(n.K()==null)break;++i}d8=s[0]
g=d8.b
if(g==null)g="COUNT(*)"
f=A.R(d8.a)
d5.e=A.a([A.a7([g,A.v(i),f,A.v(i),"COUNT(*)",A.v(i),"count(*)",A.v(i)],t.N,t.r)],t.b)
return}}}if(d9){d8=d5.c
e=d8.length
d=new Int8Array(e)
c=A.a9(e,d6,!1,t.ev)
d9=t.N
b=A.a9(e,"",!1,d9)
a=new Int32Array(e)
a0=new Float64Array(e)
a1=new Uint8Array(e)
a2=new Int32Array(e)
a3=new Float64Array(e)
s=t.g1
a4=A.a9(e,d6,!1,s)
a5=A.a9(e,d6,!1,s)
a6=A.a9(e,d6,!1,s)
for(a7=0;a7<e;++a7){a8=d8[a7]
a9=a8.a
s=a8.b
b[a7]=s==null?A.R(a9):s
if(a9 instanceof A.af){b0=a9.b.toLowerCase()
if(b0==="count"){s=a9.c
if(s.length!==0){q=s[0]
q=q instanceof A.I&&B.b.gH(q.b)==="*"}else q=!0
if(q)d[a7]=1
else{d[a7]=2
c[a7]=A.K(s[0])}}else if(b0==="sum"){d[a7]=3
c[a7]=A.K(a9.c[0])}else if(b0==="avg"){d[a7]=4
c[a7]=A.K(a9.c[0])}else if(b0==="min"){d[a7]=5
c[a7]=A.K(a9.c[0])}else if(b0==="max"){d[a7]=6
c[a7]=A.K(a9.c[0])}else{d[a7]=7
s=a9.c
if(s.length!==0)c[a7]=A.K(s[0])}}else{d[a7]=7
c[a7]=A.K(a9)}}for(d8=d5.a;;){b1=d8.K()
if(b1==null)break
for(a7=0;a7<e;++a7){b2=d[a7]
if(b2===1)a[a7]=a[a7]+1
else{b3=c[a7].$1(b1)
if(!(b3 instanceof A.d))if(b2===2)a[a7]=a[a7]+1
else if(b2===3){if(b3 instanceof A.p)a0[a7]=a0[a7]+b3.a
else if(b3 instanceof A.j){a0[a7]=a0[a7]+b3.a
a1[a7]=1}}else if(b2===4){if(b3 instanceof A.p){a3[a7]=a3[a7]+b3.a
a2[a7]=a2[a7]+1}else if(b3 instanceof A.j){a3[a7]=a3[a7]+b3.a
a2[a7]=a2[a7]+1}}else if(b2===5){b4=a4[a7]
if(b4==null||b3.A(0,b4)<0)a4[a7]=b3}else if(b2===6){b5=a5[a7]
if(b5==null||b3.A(0,b5)>0)a5[a7]=b3}else if(b2===7)if(a6[a7]==null)a6[a7]=b3}}}b6=A.o(d9,t.r)
for(a7=0;a7<e;++a7){b2=d[a7]
b7=b[a7]
if(b2===1||b2===2)b6.k(0,b7,A.v(a[a7]))
else if(b2===3)b6.k(0,b7,a1[a7]===1?new A.j(a0[a7]):A.v(B.h.be(a0[a7])))
else if(b2===4){i=a2[a7]
b6.k(0,b7,i>0?new A.j(a3[a7]/i):new A.d())}else if(b2===5){d8=a4[a7]
b6.k(0,b7,d8==null?new A.d():d8)}else if(b2===6){d8=a5[a7]
b6.k(0,b7,d8==null?new A.d():d8)}else{d8=a6[a7]
b6.k(0,b7,d8==null?new A.d():d8)}}d8=d5.d
b8=d8!=null?A.K(d8):d6
if(b8!=null){b9=b8.$1(b6)
if(b9 instanceof A.p&&b9.a===0||b9 instanceof A.d){d5.e=A.a([],t.b)
return}}d5.e=A.a([b6],t.b)
return}c0=A.o(t.N,t.bf)
d9=t.h
d7.a=A.a([],d9)
if(d8 instanceof A.cJ)d7.a=d8.b
else if(d8 instanceof A.dR){c1=d8.b
for(a7=c1.length;a7>=0;--a7)d7.a.push(B.b.bj(c1,0,a7))}else if(d8 instanceof A.dn){c1=d8.b
c2=c1.length
c3=B.c.eZ(1,c2)
for(d8=t.U,a7=0;a7<c3;++a7){c4=A.a([],d8)
for(c5=0;c5<c2;++c5)if((a7&B.c.eZ(1,c5))>>>0!==0)c4.push(c1[c5])
d7.a.push(c4)}}else d7.a=A.a([A.a([d8],t.U)],d9)
d8=d7.a
d9=A.z(d8).i("h<1,t<k(w<e,k>)>>")
c6=A.r(new A.h(d8,new A.jq(),d9),d9.i("u.E"))
d8=d7.a
d9=A.z(d8).i("h<1,t<e>>")
c7=A.r(new A.h(d8,new A.jr(),d9),d9.i("u.E"))
c8=A.o(t.gY,t.W)
for(d8=d5.c,d9=d8.length,c9=0;c9<d8.length;d8.length===d9||(0,A.n)(d8),++c9){a8=d8[c9]
a9=a8.a
s=a9 instanceof A.af
if(s&&a9.c.length!==0)c8.k(0,a8,A.K(a9.c[0]))
else if(!s)c8.k(0,a8,A.K(a9))}d9=d5.d
b8=d9!=null?A.K(d9):d6
for(d9=t.s,s=d5.a;;){b1=s.K()
if(b1==null)break
for(d0=0;d0<d7.a.length;++d0){d1=c6[d0]
d2=c7[d0]
d3=A.a([],d9)
for(q=J.X(d1),a7=0;a7<q.gt(d1);++a7)d3.push(q.h(d1,a7).$1(b1).l(0))
c0.J(""+d0+":"+B.b.S(d3,","),new A.js(d7,b1,d2)).dM(b1,d8,c8)}}d5.e=A.a([],t.b)
for(d9=new A.am(c0,c0.$ti.i("am<1,2>")).gI(0),s=b8!=null;d9.p();){d4=d9.d.b.iH(d8)
if(s){b9=b8.$1(d4)
if(b9 instanceof A.p&&b9.a===0)continue
else if(b9 instanceof A.d)continue}d5.e.push(d4)}},
K(){var s,r,q=this
if(q.e==null)q.i8()
s=q.f
r=q.e
if(s>=r.length)return null
q.f=s+1
return r[s]},
L(){this.a.L()
this.e=null},
G(a){var s,r=this,q=B.a.P("  ",a),p=r.a.G(a+1),o=r.c,n=new A.h(o,new A.jt(),A.z(o).i("h<1,e>")).S(0,", ")
o=r.d
s=o!=null?", having: "+A.R(o):""
return q+"GroupByNode(groupBy: "+A.R(r.b)+", projections: ["+n+"]"+s+")\n"+p},
a6(){return this.G(0)}}
A.jq.prototype={
$1(a){var s=J.bG(a,new A.jp(),t.W)
s=A.r(s,s.$ti.i("u.E"))
return s},
$S:81}
A.jp.prototype={
$1(a){return A.K(a)},
$S:14}
A.jr.prototype={
$1(a){var s=J.bG(a,new A.jo(),t.N)
s=A.r(s,s.$ti.i("u.E"))
return s},
$S:82}
A.jo.prototype={
$1(a){return A.R(a)},
$S:20}
A.js.prototype={
$0(){var s,r,q,p,o,n,m,l,k=A.q5(this.b,t.N,t.r),j=this.a.a
if(j.length>1){s=A.z(j).i("bX<1,e>")
r=A.oV(new A.bX(j,new A.jn(),s),s.i("F.E"))
for(j=A.fz(r,r.r,A.E(r).c),s=this.c,q=J.X(s),p=j.$ti.c,o=A.E(k).i("aL<1>");j.p();){n=j.d
if(n==null)n=p.a(n)
if(!q.E(s,n))if(k.D(n))k.k(0,n,new A.d())
else{m=B.b.gV(n.split("."))
for(n=new A.aL(k,k.r,k.e,o);n.p();){l=n.d
if(B.b.gV(l.split("."))===m)k.k(0,l,new A.d())}}}}return A.oA(k)},
$S:26}
A.jn.prototype={
$1(a){return J.bG(a,new A.jm(),t.N)},
$S:84}
A.jm.prototype={
$1(a){return A.R(a)},
$S:20}
A.jt.prototype={
$1(a){var s=a.b
return s==null?A.R(a.a):s},
$S:40}
A.dw.prototype={
gbQ(){var s=this.y
s===$&&A.b()
return s},
ghU(){var s=this.z
s===$&&A.b()
return s},
bm(){var s,r,q,p,o,n=A.o(t.N,t.r)
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
k=i.hV(l).l(0)
j=A.c2(o,n)
j.X(0,l)
J.ae(r.J(k,new A.jv()),j)
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
j=J.a_(s,c.ax++)
if(!l||p)c.ch.R(0,j)
s=c.as
s.toString
g=A.Z(s,t.N,t.r)
g.X(0,j)
return g}k=c.as=q.K()
if(k==null){if(!l||p){f=A.r(new A.aJ(o,new A.ju(c),n),m)
c.CW=new J.bd(f,f.length,A.z(f).i("bd<1>"))
continue}return null}e=c.bR(k).l(0)
if(r.D(e)){c.at=r.h(0,e)
c.ax=0}else{c.at=null
if(!s||p){d=c.bm()
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
bR(a){return this.gbQ().$1(a)},
hV(a){return this.ghU().$1(a)}}
A.jv.prototype={
$0(){return A.a([],t.b)},
$S:15}
A.ju.prototype={
$1(a){return!this.a.ch.E(0,a)},
$S:16}
A.hz.prototype={
gd8(){var s=this.x
s===$&&A.b()
return s},
bm(){var s,r,q,p,o,n=A.o(t.N,t.r)
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
n=A.c2(q,p)
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
if(j==null){if(!k||n){f=A.r(new A.aJ(s,new A.lX(a0),m),l)
a0.ax=new J.bd(f,f.length,A.z(f).i("bd<1>"))
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
if(k?n:s)a0.z.R(0,i)
return e}}j=a0.Q
j.toString
a0.Q=null
if(!a0.at)b=!o||n
else b=!1
if(b){a=a0.bm()
s=A.Z(j,r,q)
s.X(0,a)
return s}}},
L(){this.a.L()
this.b.L()
B.b.v(this.y)},
G(a){var s=a+1
return B.a.P("  ",a)+"NestedLoopJoinNode(on: "+A.R(this.c)+")\n"+this.a.G(s)+"\n"+this.b.G(s)},
a6(){return this.G(0)},
d9(a){return this.gd8().$1(a)}}
A.lX.prototype={
$1(a){return!this.a.z.E(0,a)},
$S:16}
A.dS.prototype={
ghT(){var s=this.d
s===$&&A.b()
return s},
N(){var s,r,q,p,o,n=this,m=n.a
m.N()
s=n.e
B.b.v(s)
n.f=0
for(r=t.N,q=t.r;;){p=m.K()
if(p==null)break
o=A.c2(r,q)
o.X(0,p)
s.push(o)}B.b.ar(s,new A.mN(n))},
K(){var s=this.f,r=this.e
if(s>=r.length)return null
this.f=s+1
return r[s]},
L(){this.a.L()
B.b.v(this.e)},
G(a){var s=B.a.P("  ",a),r=this.a.G(a+1)
return s+"SortNode(orderBy: "+A.R(this.b)+", asc: "+this.c+")\n"+r},
a6(){return this.G(0)},
ew(a){return this.ghT().$1(a)}}
A.mN.prototype={
$2(a,b){var s=this.a,r=s.ew(a).A(0,s.ew(b))
return s.c?r:-r},
$S:43}
A.i_.prototype={
N(){this.a.N()
this.c=null
this.d=0},
ib(){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2,b3,b4=this,b5=null,b6=t.b,b7=A.a([],b6)
for(s=t.N,r=t.r,q=b4.a;;){p=q.K()
if(p==null)break
o=A.c2(s,r)
o.X(0,p)
b7.push(o)}q=b4.b
o=q.d
n=A.z(o).i("h<1,k(w<e,k>)>")
m=A.r(new A.h(o,new A.nd(),n),n.i("u.E"))
l=A.o(s,t.c)
for(o=b7.length,n=A.z(m).i("h<1,e>"),k=0;k<b7.length;b7.length===o||(0,A.n)(b7),++k){p=b7[k]
j=m.length===0?"":new A.h(m,new A.ne(p),n).S(0,"\x00")
J.ae(l.J(j,new A.nf()),p)}i=q.e
o=i!=null
if(o){h=A.K(i.a)
g=i.b
for(n=new A.an(l,l.r,l.e,l.$ti.i("an<2>"));n.p();)J.pG(n.d,new A.ng(h,g))}f=q.b.toLowerCase()
e=A.R(q)
b4.c=A.a([],b6)
for(b6=new A.an(l,l.r,l.e,l.$ti.i("an<2>")),n=f==="lag",d=!n,c=f==="dense_rank",b=f==="rank",a=f==="lead",q=q.c;b6.p();){a0=b6.d
if(b){h=o?A.K(i.a):b5
for(a1=J.X(a0),a2=h!=null,a3=b5,a4=1,a5=0;a5<a1.gt(a0);++a5){a6=a1.h(a0,a5)
p=A.c2(s,r)
p.X(0,a6)
if(a2){a7=h.$1(p)
if(a3!=null&&a7.A(0,a3)!==0)a4=a5+1
a3=a7}else a4=a5+1
p.k(0,e,A.v(a4))
b4.c.push(p)}}else if(c){h=o?A.K(i.a):b5
for(a1=J.X(a0),a2=h!=null,a3=b5,a4=1,a5=0;a5<a1.gt(a0);++a5){a6=a1.h(a0,a5)
p=A.c2(s,r)
p.X(0,a6)
if(a2){a7=h.$1(p)
if(a3!=null&&a7.A(0,a3)!==0)++a4
a3=a7}else a4=a5+1
p.k(0,e,A.v(a4))
b4.c.push(p)}}else if(!d||a){a8=q.length!==0?A.R(B.b.gH(q)):""
for(a1=J.X(a0),a2=a8.length!==0,a5=0;a5<a1.gt(a0);++a5){a6=a1.h(a0,a5)
p=A.c2(s,r)
p.X(0,a6)
a9=n?a5-1:a5+1
if(a9>=0&&a9<a1.gt(a0)){b0=a1.h(a0,a9)
b1=new A.d()
if(a2){b2=B.b.gV(a8.split(".")).toLowerCase()
for(a6=b0.gZ(),a6=a6.gI(a6);a6.p();){b3=a6.gF()
if(B.b.gV(b3.split(".")).toLowerCase()===b2){a6=b0.h(0,b3)
a6.toString
b1=a6
break}}}else b1=J.pE(b0.gaO())?J.e6(b0.gaO()):new A.d()
p.k(0,e,b1)}else p.k(0,e,new A.d())
b4.c.push(p)}}else for(a1=J.X(a0),a5=0;a5<a1.gt(a0);){a2=a1.h(a0,a5)
p=A.c2(s,r)
p.X(0,a2);++a5
p.k(0,e,A.v(a5))
b4.c.push(p)}}},
K(){var s,r,q=this
if(q.c==null)q.ib()
s=q.d
r=q.c
if(s>=r.length)return null
q.d=s+1
return r[s]},
L(){this.a.L()
this.c=null},
G(a){return B.a.P("  ",a)+"WindowNode(func: "+this.b.b+")"},
a6(){return this.G(0)}}
A.nd.prototype={
$1(a){return A.K(a)},
$S:14}
A.ne.prototype={
$1(a){return J.x(a.$1(this.a))},
$S:37}
A.nf.prototype={
$0(){return A.a([],t.b)},
$S:15}
A.ng.prototype={
$2(a,b){var s=this.a,r=s.$1(a).A(0,s.$1(b))
return this.b?r:-r},
$S:43}
A.hi.prototype={
N(){this.r=null
this.w=0},
hv(){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0=this,b1=null
b0.r=A.a([],t.b)
k=b0.f
j=b0.a
i=J.au(k.bu(j))
h=b0.b
for(;;){if(!i.p()){l=b1
break}l=i.gF()
if(l.d==="fts"&&l.c.toLowerCase()===h.toLowerCase())break}i=b0.d
g=l==null?b1:l.a.toLowerCase()
h=g==null?"fts_"+j+"_"+h:g
g=t.N
f=new A.hh(i+"/"+h+".fts",A.o(g,t.eb))
f.ap()
h=A.S(b0.c,"'","")
e=f.bi(A.S(h,'"',""))
if(e.length===0)return
d=k.c.h(0,j.toLowerCase().toLowerCase())
if(d==null)return
k=b0.e
j=d.a
c=A.aR(k,i,j)
c.bE()
for(i=e.length,h=c.c+"/"+c.b+".db",b=k.ax,a=d.b,a0=t.r,a1=0;a1<e.length;e.length===i||(0,A.n)(e),++a1){a2=e[a1]
a3=a2.a
s=A.ab(k.C(h,a3),a2.b)
if(s!=null){r=null
try{q=A.aV(s)
p=k.ga5()
o=b
a4=p
a5=a4==null?b1:a4.a
n=a5==null?0:a5
a4=p
a6=a4==null?b1:a4.b
m=a6==null?B.u:a6
if(o.aD(q.a,q.b,n,m))r=A.a4(q.d,b1,b1)}catch(a7){r=A.a4(s,b1,b1)}if(r!=null){a8=A.o(g,a0)
for(a9=0;a9<a.length;++a9){a4=d.dx
a4===$&&A.b()
a8.k(0,j.toLowerCase()+"."+a4[a9],J.a_(r,a9))
a8.k(0,a4[a9],J.a_(r,a9))}b0.r.push(a8)}}k.u(h,a3,!1)}},
K(){var s,r,q=this
if(q.r==null)q.hv()
s=q.w
r=q.r
if(s>=r.length)return null
q.w=s+1
return r[s]},
L(){this.r=null},
G(a){return B.a.P("  ",a)+"FtsScanNode(table: "+this.a+", column: "+this.b+', query: "'+this.c+'")'},
a6(){return this.G(0)}}
A.dE.prototype={
N(){this.b=0},
K(){var s=this.b,r=this.a
if(s>=r.length)return null
this.b=s+1
return r[s]},
L(){},
G(a){return B.a.P("  ",a)+"MemoryScanNode(rowCount: "+this.a.length+")"},
a6(){return this.G(0)}}
A.hL.prototype={
N(){this.a.N()
this.c=null
this.d=0},
hz(){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c=this,b=t.b
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
l=n.$1(new A.dE(A.a6(s,!0,r)))
l.N()
k=A.a([],b)
for(;;){o=l.K()
if(o==null)break
j=A.o(q,p)
i=c.c
if(i.length!==0){i=B.b.gH(i)
h=A.E(i).i("aB<1>")
g=A.r(new A.aB(i,h),h.i("F.E"))
f=J.fX(o.gaO())
for(e=0;e<g.length;++e){d=e<f.length?f[e]:new A.d()
j.k(0,g[e],d)
j.k(0,B.b.gV(g[e].split(".")),d)}}else j.X(0,o)
i=c.c
i.toString
if(!B.b.b1(i,new A.mJ(j))){c.c.push(j)
k.push(j)}}l.L()
B.b.v(s)
B.b.X(s,k)}},
K(){var s,r,q=this
if(q.c==null)q.hz()
s=q.d
r=q.c
if(s>=r.length)return null
q.d=s+1
return r[s]},
L(){this.a.L()
this.c=null},
G(a){return B.a.P("  ",a)+"RecursiveCteNode()"},
a6(){return this.G(0)}}
A.mJ.prototype={
$1(a){var s,r,q
for(s=this.a,r=new A.aL(s,s.r,s.e,A.E(s).i("aL<1>"));r.p();){q=r.d
if(!J.az(a.h(0,q),s.h(0,q)))return!1}return!0},
$S:16}
A.cP.prototype={
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
A.o2.prototype={
$1(a){return A.cA(B.a.W(a))},
$S:9}
A.dx.prototype={
gbQ(){var s=this.y
s===$&&A.b()
return s},
bm(){var s,r,q,p,o,n=A.o(t.N,t.r)
for(s=this.e,r=s.b,q=r.length,s=s.a+".",p=0;p<r.length;r.length===q||(0,A.n)(r),++p){o=r[p]
n.k(0,s+o,new A.d())
n.k(0,o,new A.d())}return n},
N(){var s,r,q,p,o,n,m,l,k,j,i,h=this
h.a.N()
h.c.ap()
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
l=r.fN(p.b,m,n.length,q.ax)}else l=r.fM(n.length)
k=A.o(t.N,t.S)
for(r=o.a+".",j=0;j<n.length;++j){i=n[j]
k.k(0,r+i,j)
k.k(0,i,j)}while(l.p()){r=l.ax
r.toString
s.push(new A.aN(r,k))}}},
eS(a,b){var s,r,q,p
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
if(a0==null){if(!e||q){a1=A.r(new A.aJ(h,new A.jJ(b3),g),f)
b3.ay=new J.bd(a1,a1.length,A.z(a1).i("bd<1>"))
continue}return b4}a2=b3.bR(a0)
if(a2 instanceof A.p)a3=a2.a
else a3=a2 instanceof A.j?a2.a:b4
if(a3!=null){if(p.D(a3)){c=p.h(0,a3)
if(c!=null){if(!e||q)for(s=h.length,a=0;a<h.length;h.length===s||(0,A.n)(h),++a){a4=h[a]
if(b3.eS(a4,c)){b3.ax.R(0,a4)
break}}a5=A.Z(a0,t.N,t.r)
a5.X(0,c)
return a5}if(!s||q){a6=b3.bm()
a5=A.Z(a0,t.N,t.r)
a5.X(0,a6)
return a5}continue}a7=o.bi(A.a([a3],n))
if(a7!=null){d=b3.Q
a8=a7.a
if(d!==a8){if(b3.z!=null){d.toString
l.u(k,d,!1)}b3.z=l.C(k,a8)
b3.Q=a8}d=b3.z
d.toString
a9=A.ab(d,a7.b)
if(a9!=null){b0=A.qN(m,a9,i.length)
if(b0!=null){s=t.N
r=t.r
c=A.o(s,r)
for(o=j.a+".",b1=0;b1<i.length;++b1)if(b1<b0.length){b2=i[b1]
c.k(0,o+b2,b0[b1])
c.k(0,b2,b0[b1])}p.k(0,a3,c)
if(!e||q)for(q=h.length,a=0;a<h.length;h.length===q||(0,A.n)(h),++a){a4=h[a]
if(b3.eS(a4,c)){b3.ax.R(0,a4)
break}}a5=A.Z(a0,s,r)
a5.X(0,c)
return a5}}}p.k(0,a3,b4)
if(!s||q){a6=b3.bm()
a5=A.Z(a0,t.N,t.r)
a5.X(0,a6)
return a5}}else if(!s||q){a6=b3.bm()
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
G(a){var s=this,r=B.a.P("  ",a),q=s.a.G(a+1),p=B.b.gV(s.c.b.split("/"))
return r+"IndexJoinNode(on: "+s.d+" = "+s.e.a+"."+A.S(p,".idx","")+")\n"+q},
a6(){return this.G(0)},
bR(a){return this.gbQ().$1(a)}}
A.jJ.prototype={
$1(a){return!this.a.ax.E(0,a)},
$S:16}
A.dv.prototype={
gbQ(){var s=this.w
s===$&&A.b()
return s},
N(){this.a.N()
var s=this.d
if(s!=null)s.ap()},
K(){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2,b3,b4,b5,b6,b7,b8=this,b9=null
for(s=b8.b,r=s!=null,q=b8.c,p=q!=null,o=b8.d,n=o!=null,m=b8.a,l=b8.f,k=b8.r,j=k.b,i=k.a+".",h=t.N,g=t.r,f=t.bq,e=f.i("u.E"),d=t.f8,c=t.n;;){b=m.K()
if(b==null)return b9
a=b8.bR(b)
if(n&&r){if(a instanceof A.p)a0=a.a
else a0=a instanceof A.j?a.a:b9
if(a0!=null){a1=o.bi(A.a([a0],c))
if(a1!=null){a2=s.a
a3=s.c+"/"+s.b+".db"
a4=a1.a
a5=A.ab(a2.C(a3,a4),a1.b)
if(a5!=null){a6=A.qN(s,a5,j.length)
if(a6!=null){a7=A.o(h,g)
for(a8=0;a8<j.length;++a8)if(a8<a6.length){a9=j[a8]
a7.k(0,i+a9,a6[a8])
a7.k(0,a9,a6[a8])}a2.u(a3,a4,!1)
b0=A.Z(b,h,g)
b0.X(0,a7)
return b0}}a2.u(a3,a4,!1)}}}else if(p){a2=k.dx
a2===$&&A.b()
b1=B.b.ad(a2,l.toLowerCase())
if(b1!==-1){b2=A.a([],d)
for(a8=0;a8<j.length;++a8){a2=q.cO(a8)
b2.push(new A.ca(a2.a(),a2.$ti.i("ca<1>")))}a2=b2.length
b3=a2!==0
for(b4=0;b4<b2.length;b2.length===a2||(0,A.n)(b2),++b4)if(!b2[b4].p())b3=!1
for(;;){if(!b3){b5=b9
break}b6=A.r(new A.h(b2,new A.jl(),f),e)
if(b1<b6.length)if(b6[b1].A(0,a)===0){b5=A.o(h,g)
for(a8=0;a8<j.length;++a8){a9=j[a8]
b5.k(0,i+a9,b6[a8])
b5.k(0,a9,b6[a8])}break}for(a2=b2.length,b4=0;b4<b2.length;b2.length===a2||(0,A.n)(b2),++b4)if(!b2[b4].p())b3=!1}if(b5!=null){b0=A.Z(b,h,g)
b0.X(0,b5)
return b0}}}else if(r){a2=k.dx
a2===$&&A.b()
b1=B.b.ad(a2,l.toLowerCase())
if(b1!==-1){b7=s.fL()
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
bR(a){return this.gbQ().$1(a)}}
A.jl.prototype={
$1(a){return a.gF()},
$S:87}
A.hk.prototype={
N(){var s,r,q=this,p=q.c
p.ap()
s=q.r
r=s!=null?new A.jI(q,A.K(s)):null
q.w=p.cP(q.d,q.e,r)
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
if(j!=null){i=A.bV(A.aq(j,0,e),0,j.length)
h=d[l]
r.k(0,o+h,i)
r.k(0,h,i)}q.u(k,n,!1)}}else{o=q.a
q=p+"/"+q.b+".db"
p=s.c
j=A.ab(o.C(q,p),s.d)
if(j==null){o.u(q,p,!1)
return f.K()}g=A.a4(j,e,e)
for(n=d.b,d=d.a+".",l=0;l<n.length;++l)if(l<g.length){h=n[l]
r.k(0,d+h,g[l])
r.k(0,h,g[l])}o.u(q,p,!1)}return r},
L(){this.w=null},
G(a){var s=B.a.P("  ",a),r=this.r,q=r!=null?", filter: "+A.R(r):""
return s+"HnswScanNode(table: "+this.b.a+", limit: "+this.e+", maxDistance: null"+q+")"},
a6(){return this.G(0)}}
A.jI.prototype={
$2(a,a0){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d=A.o(t.N,t.r),c=this.a,b=c.b
c=c.a
g=c.c
if(b.d){f=b.a
for(s=0,b=b.b,c=c.a,g=g+"/"+f+".col_",f+=".";s<b.length;++s){r=g+A.D(s)
if(a>=c.a_(r).a4())return!1
q=c.C(r,a)
try{p=A.ab(q,a0)
if(p!=null){o=A.aq(p,0,null)
n=A.bV(o,0,p.length)
m=b[s]
J.aX(d,f+A.D(m),n)
J.aX(d,m,n)}}finally{c.u(r,a,!1)}}}else{f=c.a
c=g+"/"+c.b+".db"
l=f.C(c,a)
try{k=A.ab(l,a0)
if(k==null)return!1
j=A.a4(k,null,null)
for(i=0,g=b.b,b=b.a+".";i<g.length;++i)if(i<J.O(j)){h=g[i]
J.aX(d,b+A.D(h),J.a_(j,i))
J.aX(d,h,J.a_(j,i))}}finally{f.u(c,a,!1)}}e=this.b.$1(d)
if(!(e instanceof A.p&&e.a===1))c=e instanceof A.j&&e.a>0
else c=!0
return c},
$S:44}
A.hp.prototype={
N(){var s,r,q=this,p=q.c
p.ap()
s=q.r
r=s!=null?new A.l1(q,A.K(s)):null
q.w=p.cP(q.d,q.e,r)
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
if(j!=null){i=A.bV(A.aq(j,0,e),0,j.length)
h=d[l]
r.k(0,o+h,i)
r.k(0,h,i)}q.u(k,n,!1)}}else{o=q.a
q=p+"/"+q.b+".db"
p=s.b
j=A.ab(o.C(q,p),s.c)
if(j==null){o.u(q,p,!1)
return f.K()}g=A.a4(j,e,e)
for(n=d.b,d=d.a+".",l=0;l<n.length;++l)if(l<g.length){h=n[l]
r.k(0,d+h,g[l])
r.k(0,h,g[l])}o.u(q,p,!1)}return r},
L(){this.w=null},
G(a){var s=B.a.P("  ",a),r=this.r,q=r!=null?", filter: "+A.R(r):""
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
if(p!=null){o=A.aq(p,0,null)
n=A.bV(o,0,p.length)
m=b[s]
J.aX(d,f+A.D(m),n)
J.aX(d,m,n)}}finally{c.u(r,a,!1)}}}else{f=c.a
c=g+"/"+c.b+".db"
l=f.C(c,a)
try{k=A.ab(l,a0)
if(k==null)return!1
j=A.a4(k,null,null)
for(i=0,g=b.b,b=b.a+".";i<g.length;++i)if(i<J.O(j)){h=g[i]
J.aX(d,b+A.D(h),J.a_(j,i))
J.aX(d,h,J.a_(j,i))}}finally{f.u(c,a,!1)}}e=this.b.$1(d)
if(!(e instanceof A.p&&e.a===1))c=e instanceof A.j&&e.a>0
else c=!0
return c},
$S:44}
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
A.hU.prototype={
fW(a,b){var s,r
for(s=this.b,r=0;r<s.length;++r)if(!s[r])this.f=r},
N(){var s,r,q=this,p=q.c=0
q.d.v(0)
q.e=null
for(s=q.a,r=s.length;p<s.length;s.length===r||(0,A.n)(s),++p)s[p].N()},
b_(a){if(a instanceof A.aN)return a.a
return J.fX(a.gaO())},
bO(a){var s
if(a instanceof A.aN){s=A.a9(a.a.length,"",!1,t.N)
a.b.a1(0,new A.n9(s))
return s}return a.gZ().bd(0,new A.na(),t.N).aN(0)},
K(){var s,r,q,p,o,n,m,l,k,j=this
for(s=j.a,r=j.d;q=j.c,q<s.length;){p=s[q].K()
if(p==null){++j.c
continue}o=j.b_(p)
if(j.e==null)j.e=j.bO(p)
q=j.f
if(q!==-1&&j.c<=q+1)if(!r.R(0,new A.bC(o)))continue
n=A.o(t.N,t.r)
for(m=0;s=j.e,m<s.length;++m){l=s[m]
k=m<o.length?o[m]:new A.d()
n.k(0,l,k)
n.k(0,B.b.gV(l.split(".")),k)}return n}return null},
L(){var s,r,q
for(s=this.a,r=s.length,q=0;q<s.length;s.length===r||(0,A.n)(s),++q)s[q].L()},
G(a){var s,r,q,p=B.a.P("  ",a)+"UnionNode(isAllFlags: "+A.D(this.b)+")\n"
for(s=this.a,r=a+1,q=0;q<s.length;++q){p+=s[q].G(r)
if(q<s.length-1)p+="\n"}return p.charCodeAt(0)==0?p:p},
a6(){return this.G(0)}}
A.n9.prototype={
$2(a,b){var s,r=this.a
if(b<r.length){s=B.b.gV(a.split("."))
if(r[b].length===0||!B.a.E(a,"."))r[b]=s}},
$S:10}
A.na.prototype={
$1(a){return B.b.gV(a.split("."))},
$S:7}
A.hn.prototype={
N(){var s,r,q,p=this
for(s=p.a,r=s.length,q=0;q<s.length;s.length===r||(0,A.n)(s),++q)s[q].N()
p.b.v(0)
p.d=p.c=null
p.e=!1},
b_(a){if(a instanceof A.aN)return a.a
return J.fX(a.gaO())},
bO(a){var s
if(a instanceof A.aN){s=A.a9(a.a.length,"",!1,t.N)
a.b.a1(0,new A.kU(s))
return s}return a.gZ().aN(0)},
da(){var s,r,q,p,o,n,m=this
if(m.e)return
m.e=!0
m.c=A.a([],t.bA)
for(s=m.a,r=t.Y,q=1;q<s.length;++q){p=A.aD(r)
o=s[q]
for(;;){n=o.K()
if(n==null)break
p.R(0,new A.bC(m.b_(n)))}m.c.push(p)}},
K(){var s,r,q,p,o,n,m,l,k,j,i,h,g=this
g.da()
for(s=g.b,r=g.a;;){q=r[0].K()
if(q==null)return null
p=g.b_(q)
if(g.d==null)g.d=g.bO(q)
o=new A.bC(p)
m=g.c
l=m.length
k=0
for(;;){if(!(k<m.length)){n=!0
break}if(!m[k].E(0,o)){n=!1
break}m.length===l||(0,A.n)(m);++k}if(!n)continue
if(!s.R(0,o))continue
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
$S:10}
A.hd.prototype={
N(){var s,r,q,p=this
for(s=p.a,r=s.length,q=0;q<s.length;s.length===r||(0,A.n)(s),++q)s[q].N()
p.b.v(0)
p.d=p.c=null
p.e=!1},
b_(a){if(a instanceof A.aN)return a.a
return J.fX(a.gaO())},
bO(a){var s
if(a instanceof A.aN){s=A.a9(a.a.length,"",!1,t.N)
a.b.a1(0,new A.j6(s))
return s}return a.gZ().aN(0)},
da(){var s,r,q,p,o,n,m=this
if(m.e)return
m.e=!0
m.c=A.a([],t.bA)
for(s=m.a,r=t.Y,q=1;q<s.length;++q){p=A.aD(r)
o=s[q]
for(;;){n=o.K()
if(n==null)break
p.R(0,new A.bC(m.b_(n)))}m.c.push(p)}},
K(){var s,r,q,p,o,n,m,l,k,j,i,h,g=this
g.da()
for(s=g.b,r=g.a;;){q=r[0].K()
if(q==null)return null
p=g.b_(q)
if(g.d==null)g.d=g.bO(q)
o=new A.bC(p)
m=g.c
l=m.length
k=0
for(;;){if(!(k<m.length)){n=!1
break}if(m[k].E(0,o)){n=!0
break}m.length===l||(0,A.n)(m);++k}if(n)continue
if(!s.R(0,o))continue
j=A.o(t.N,t.r)
for(i=0;s=g.d,i<s.length;++i){h=s[i]
j.k(0,h,i<p.length?p[i]:new A.d())}return j}},
L(){var s,r,q
for(s=this.a,r=s.length,q=0;q<s.length;s.length===r||(0,A.n)(s),++q)s[q].L()},
G(a){var s,r,q,p=B.a.P("  ",a)+"ExceptNode\n"
for(s=this.a,r=a+1,q=0;q<s.length;++q){p+=s[q].G(r)
if(q<s.length-1)p+="\n"}return p.charCodeAt(0)==0?p:p},
a6(){return this.G(0)}}
A.j6.prototype={
$2(a,b){var s,r=this.a
if(b<r.length){s=r[b]
if(s.length===0||B.a.E(s,"."))r[b]=a}},
$S:10}
A.h9.prototype={
N(){this.a.N()
this.b.v(0)},
b_(a){if(a instanceof A.aN)return a.a
return J.fX(a.gaO())},
K(){var s,r,q
for(s=this.b,r=this.a;;){q=r.K()
if(q==null)return null
if(!s.R(0,new A.bC(this.b_(q))))continue
return q}},
L(){this.a.L()
this.b.v(0)},
G(a){return B.a.P("  ",a)+"DistinctNode\n"+this.a.G(a+1)},
a6(){return this.G(0)}}
A.mo.prototype={
hH(a,b){var s=A.o(t.N,t.k),r=a.b,q=0
for(;;){if(!(q<r.length&&q<b.length))break
s.k(0,r[q].toLowerCase(),b[q]);++q}return new A.mp(s).$1(a.c)},
bS(a,b){var s,r,q,p=B.a.W(a),o=new A.mr()
while(o.$1(p))p=B.a.W(B.a.O(p,1,p.length-1))
s=A.aI("\\s+",!0)
r=A.S(p,s,"").toLowerCase()
q=b.toLowerCase()+"."
if(B.a.U(r,q))return B.a.az(r,q.length)
return r},
d4(a){var s,r=this.a.c.h(0,a.b.toLowerCase().toLowerCase())
if(r==null)return 1
s=a.c
return B.b.cq(A.a(s.split(","),t.s),new A.mq(r))?s.split(",").length:1},
iw(a){var s=this
if(a instanceof A.cW)return s.j6(a)
if(a instanceof A.dy)return s.j5(a)
if(a instanceof A.dr)return s.j3(a)
if(a instanceof A.aS)return s.aL(a)
throw A.c(A.q("Unsupported statement type for query planner: "+A.fV(a).l(0)))},
j6(a){var s=a.a,r=A.z(s).i("h<1,P>"),q=A.r(new A.h(s,new A.mE(this),r),r.i("u.E"))
return A.qt(q,a.b)},
j5(a){var s=a.a,r=A.z(s).i("h<1,P>"),q=A.r(new A.h(s,new A.my(this),r),r.i("u.E"))
return new A.hn(q,A.aD(t.Y))},
j3(a){var s=a.a,r=A.z(s).i("h<1,P>"),q=A.r(new A.h(s,new A.mv(this),r),r.i("u.E"))
return new A.hd(q,A.aD(t.Y))},
aL(m3){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2,b3,b4,b5,b6,b7,b8,b9,c0,c1,c2,c3,c4,c5,c6,c7,c8,c9,d0,d1,d2,d3,d4,d5,d6,d7,d8,d9,e0,e1,e2,e3,e4,e5,e6,e7,e8,e9,f0,f1,f2,f3,f4,f5,f6,f7,f8,f9,g0,g1,g2,g3,g4,g5,g6,g7,g8,g9,h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,i0,i1,i2,i3,i4,i5,i6,i7,i8,i9,j0,j1,j2,j3,j4,j5,j6,j7,j8,j9,k0,k1,k2,k3,k4,k5,k6,k7,k8,k9,l0,l1,l2,l3,l4,l5,l6,l7,l8=this,l9=null,m0="' does not exist in catalog.",m1="euclidean",m2="' does not exist."
m3=m3
if(m3 instanceof A.dm)if(m3.CW){c=m3.ay
b=new A.aB(c,A.E(c).i("aB<1>")).gH(0)
c=m3.ay.h(0,b)
c.toString
if(c instanceof A.cW){c=c.a
a=B.b.gH(c)
a0=B.b.gV(c)}else{if(!(c instanceof A.aS))return l8.aL(l8.cg(m3.ch,m3.ay))
a0=c
a=a0}return l8.i9(m3,a,a0,b)}else return l8.aL(l8.cg(m3.ch,m3.ay))
m3=l8.ig(m3)
a1=A.qu()
m3.toString
a2=!1
a3=!1
a4=!1
if(m3.c!=null){c=m3.c
c.toString
a5=l8.aL(c)
c=t.s
s=A.a([],c)
r=A.a([],t.d)
for(a6=m3.c.a,a7=a6.length,a8=0;a8<a6.length;a6.length===a7||(0,A.n)(a6),++a8){a9=a6[a8]
b0=a9.b
if(b0!=null)s.push(b0)
else{b0=a9.a
if(b0 instanceof A.I)s.push(B.b.gV(b0.b))
else s.push(A.R(b0))}r.push(B.t)}b1=m3.e
b2=A.bL(l9,l9,l9,s,l9,l9,l9,l9,r,l9,l9,l9,!1,!1,b1==null?"subquery":b1,l9,l9,l9,l9,l9,l9)
a1.b=new A.dU(a5,m3.e)
b3=m3.a
if(b3.length===1){a6=b3[0].a
a6=a6 instanceof A.I&&B.b.gH(a6.b)==="*"}else a6=!1
if(a6){h=A.a([],t.u)
for(a6=b2.b,a7=a6.length,a8=0;a8<a6.length;a6.length===a7||(0,A.n)(a6),++a8)h.push(new A.ai(new A.I(A.a([a6[a8]],c)),l9))
for(a6=m3.f,a7=a6.length,b0=l8.a.c,a8=0;a8<a6.length;a6.length===a7||(0,A.n)(a6),++a8){b4=b0.h(0,a6[a8].a.toLowerCase().toLowerCase())
if(b4!=null)for(b5=b4.b,b6=b5.length,b7=b4.a,b8=0;b8<b5.length;b5.length===b6||(0,A.n)(b5),++b8)h.push(new A.ai(new A.I(A.a([b7,b5[b8]],c)),l9))}b3=h}}else if(m3.d!=null){c=t.s
s=A.a([],c)
r=A.a([],t.d)
try{a6=m3.d
a6.toString
q=A.bO(a6,A.o(t.N,t.r))
A.cd("--- TVF EVAL VAL: "+A.D(q)+" ("+A.fV(q).l(0)+") ---")
p=[]
if(q instanceof A.aO)p=q.a
else if(q instanceof A.L&&t.j.b(q.ga2()))p=t.j.a(q.ga2())
else if(q instanceof A.m)try{o=B.o.ag(q.a)
if(t.j.b(o))p=o}catch(b9){}if(J.pE(p)){n=J.e6(p)
a6=t.f
if(a6.b(n))for(a6=n.gZ(),a6=a6.gI(a6);a6.p();){m=a6.gF()
J.ae(s,J.x(m))
J.ae(r,B.t)}else{a7=t.j
if(a7.b(n))for(l=0;l<J.O(n);++l){J.ae(s,"col"+A.D(l))
J.ae(r,B.t)}else if(n instanceof A.L&&a6.b(n.ga2())){k=a6.a(n.ga2())
for(a6=k.gZ(),a6=a6.gI(a6);a6.p();){j=a6.gF()
J.ae(s,J.x(j))
J.ae(r,B.t)}}else if(n instanceof A.aO)for(i=0;i<n.a.length;++i){J.ae(s,"col"+A.D(i))
J.ae(r,n.a[i].gae())}else if(n instanceof A.L&&a7.b(n.ga2())){h=a7.a(n.ga2())
for(g=0;g<J.O(h);++g){J.ae(s,"col"+A.D(g))
J.ae(r,B.t)}}else{J.ae(s,"value")
a6=n instanceof A.k?n.gae():B.t
J.ae(r,a6)}}}}catch(b9){}if(J.O(s)===0){J.ae(s,"value")
J.ae(r,B.t)}c0=m3.e
if(c0==null)c0=m3.d.b
b2=A.bL(l9,l9,l9,s,l9,l9,l9,l9,r,l9,l9,l9,!1,!1,c0,l9,l9,l9,l9,l9,l9)
a6=m3.d
a6.toString
a1.b=new A.hj(a6,m3.e)
b3=m3.a
if(b3.length===1){a6=b3[0].a
a6=a6 instanceof A.I&&B.b.gH(a6.b)==="*"}else a6=!1
if(a6){h=A.a([],t.u)
for(a6=b2.b,a7=a6.length,a8=0;a8<a6.length;a6.length===a7||(0,A.n)(a6),++a8)h.push(new A.ai(new A.I(A.a([a6[a8]],c)),l9))
a6=m3.f
if((a6.length!==0?B.b.gH(a6):l9)!=null){a6=m3.f
b4=l8.a.c.h(0,(a6.length!==0?B.b.gH(a6):l9).a.toLowerCase().toLowerCase())
if(b4!=null)for(a6=b4.b,a7=a6.length,b0=b4.a,a8=0;a8<a6.length;a6.length===a7||(0,A.n)(a6),++a8)h.push(new A.ai(new A.I(A.a([b0,a6[a8]],c)),l9))}b3=h}}else{c1=m3.b.toLowerCase()
c=l8.a
a6=c.c
c2=a6.h(0,c1.toLowerCase())
a7=c2==null
b0=a7?l9:c2.at
A.cd("Planner loaded schema for "+c1+": isForeign="+A.D(b0))
if(a7)if(c1.length===0){s=A.a([],t.s)
r=A.a([],t.d)
for(a7=m3.a,b0=a7.length,a8=0;a8<a7.length;a7.length===b0||(0,A.n)(a7),++a8){a9=a7[a8]
b5=a9.b
if(b5!=null)s.push(b5)
else{b5=a9.a
if(b5 instanceof A.I)s.push(B.b.gV(b5.b))
else s.push(A.R(b5))}r.push(B.t)}if(s.length===0){s.push("dual")
r.push(B.t)}b2=A.bL(l9,l9,l9,s,l9,l9,l9,l9,r,l9,l9,l9,!1,!1,"dual",l9,l9,l9,l9,l9,l9)
a1.b=new A.dE(A.a([A.o(t.N,t.r)],t.b))}else throw A.c(A.q("Table '"+c1+m0))
else b2=c2
b3=m3.a
if(b3.length===1){a7=b3[0].a
a7=a7 instanceof A.I&&B.b.gH(a7.b)==="*"}else a7=!1
if(a7){h=A.a([],t.u)
for(a7=b2.b,b0=a7.length,b5=t.s,a8=0;a8<a7.length;a7.length===b0||(0,A.n)(a7),++a8)h.push(new A.ai(new A.I(A.a([a7[a8]],b5)),l9))
for(a7=m3.f,b0=a7.length,a8=0;a8<a7.length;a7.length===b0||(0,A.n)(a7),++a8){b4=a6.h(0,a7[a8].a.toLowerCase().toLowerCase())
if(b4!=null)for(b6=b4.b,b7=b6.length,c3=b4.a,b8=0;b8<b6.length;b6.length===b7||(0,A.n)(b6),++b8)h.push(new A.ai(new A.I(A.a([c3,b6[b8]],b5)),l9))}b3=h}a6=b2.db
if(a6.length!==0){c4=A.a([],t.bL)
for(c=a6.length,a7=t.s,b0=t.u,a8=0;a8<a6.length;a6.length===c||(0,A.n)(a6),++a8){c5=a6[a8]
b5=A.a([new A.ai(new A.I(A.a(["*"],a7)),l9)],b0)
c6=l8.aL(new A.aS(b5,c5,l9,l9,l9,B.b9,l9,l9,l9,l9,l9,l9,l9,!1,l9))
c7=m3.e
c4.push(new A.dU(c6,c7==null?m3.b:c7))}c=c4.length
if(c===0)a1.b=new A.dE(A.a([],t.b))
else if(c===1)a1.b=B.b.gH(c4)
else a1.b=A.qt(c4,A.a9(c-1,!0,!1,t.y))}else{if(m3.y!=null){c8=m3.y.a
if(c8 instanceof A.af&&c8.b.toLowerCase()==="vector_distance")c9=c8
else{c9=l9
if(c8 instanceof A.I){d0=B.b.gV(c8.b).toLowerCase()
for(a6=m3.a,a7=a6.length,b0=t.du,a8=0;a8<a7;++a8){a9=a6[a8]
b5=a9.b
if((b5==null?l9:b5.toLowerCase())===d0&&a9.a instanceof A.af){d1=b0.a(a9.a)
if(d1.b.toLowerCase()==="vector_distance"){c9=d1
break}}}}}if(c9!=null){a6=c9.c.length
a6=a6===2||a6===3}else a6=!1
if(a6){a6=c9.c
d2=a6[0]
if(d2 instanceof A.I){d3=c.b5(c1,B.b.gV(d2.b).toLowerCase())
if(d3!=null){a7=d3.d
a7=a7==="hnsw"||a7==="ivf_flat"}else a7=!1
if(a7){a7=t.N
b0=t.r
f=A.bO(a6[1],A.o(a7,b0))
if(f instanceof A.m){e=B.a.W(f.a)
if(J.rR(e,"[")&&J.rN(e,"]"))try{b5=t.dh
p=A.r(new A.h(A.a(J.rS(e,1,J.O(e)-1).split(","),t.s),new A.mz(),b5),b5.i("u.E"))
d=p
f=new A.a5(d)}catch(b9){}}if(f instanceof A.a5){if(a6.length===3){d4=A.bO(a6[2],A.o(a7,b0))
d5=d4 instanceof A.m?d4.a.toLowerCase():m1}else d5=m1
d6=m3.z
if(d6==null)d6=10
c=l8.c
d7=A.aR(l8.b,c,b2.a)
d8=d3.d==="ivf_flat"
a6=d3.a
a7=d8?"ivf_flat":"hnsw"
d9=c+"/"+a6.toLowerCase()+"."+a7
e0=d8?new A.hp(d7,b2,A.q_(!1,d9,d5),f,d6,m3.r):new A.hk(d7,b2,A.oL(!1,d9,d5),f,d6,m3.r)
c=b2.Q
if(c.length!==0){e1=B.b.gH(c).b
for(a6=c.length,l=1;l<a6;++l)e1=new A.a0("OR",e1,c[l].b)
e0=A.eu(e0,e1)}b3=m3.a
if(b3.length===1){c=b3[0].a
c=c instanceof A.I&&B.b.gH(c.b)==="*"}else c=!1
if(c){h=A.a([],t.u)
for(c=b2.b,a6=c.length,a7=t.s,a8=0;a8<c.length;c.length===a6||(0,A.n)(c),++a8)h.push(new A.ai(new A.I(A.a([c[a8]],a7)),l9))
b3=h}return A.hK(e0,b3)}}}}}a6=b2.d
e2=l9
e3=l9
e4=l9
if(!a6&&m3.r!=null){a7=m3.r
a7.toString
e5=A.pf(a7)
if(e5!=null){a1.b=new A.hi(c1,e5.b,e5.c,l8.c,l8.b,c)
a3=!0}else{for(a7=J.au(c.bu(c1)),b0=t.s,b5=t.e,b6=b5.i("u.E"),e6=e4,e7=e3,e8=e2,e9=-1;a7.p();){f0=a7.gF()
f1=A.r(new A.h(A.a(f0.c.split(","),b0),new A.mA(),b5),b6)
if(f1.length===0)continue
b7=m3.r
b7.toString
f2=l8.ej(b7,c1,f1)
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
break}if(e7[l]!==e6[l])break;++l}}if(f7){f8=c?l9:f5.b.h(0,B.a.W(B.b.gH(e8.c.split(","))).toLowerCase())
f9=f8==null?l9:f8.c
if(f9==null)f9=10
g0=f9>0?1/f9:0.01}else{b6=B.a.W(B.b.gH(e8.c.split(",")))
f8=c?l9:f5.b.h(0,b6.toLowerCase())
c=f8==null
g1=c?l9:f8.a
g2=c?l9:f8.b
g3=a7&&e7.length!==0?e7[0]:l9
g4=e6!=null&&e6.length!==0?e6[0]:l9
if(typeof g1=="number"&&typeof g2=="number"&&g2>g1){g5=g3==null?g1:g3
g0=((g4==null?g2:g4)-g5)/(g2-g1)}else g0=0.1}g0=B.h.dt(g0,0,1)
a3=f7||g0*f6<0.4*f6
if(a3){g6=A.aD(t.N)
c=m3.r
c.toString
l8.af(c,g6)
g7=new A.h(A.a(e8.c.split(","),b0),new A.mB(),b5).je(0)
g8=!1
if(m3.r instanceof A.a0){g9=t.el.a(m3.r)
if(g9.b==="="&&g9.c instanceof A.I)g8=g7.E(0,B.a.W(B.b.gV(t.w.a(g9.c).b).toLowerCase()))}if(!g8)a4=!0
else for(c=A.fz(g6,g6.r,g6.$ti.c),a7=c.$ti.c;c.p();){b0=c.d
if(b0==null)b0=a7.a(b0)
if(!g7.E(0,B.b.gV(B.a.W(b0.toLowerCase()).split(".")))){a4=!0
break}}}e4=e6
e3=e7
e2=e8}}}if(a6)a1.b=A.pN(new A.bS(l8.b,b2.a,l8.c),b2,l8.eo(m3,b2))
else if(a3&&e2!=null){c=l8.c
a6=l8.b
h0=A.h1(a6,c+"/"+e2.a.toLowerCase()+".idx",l8.d4(e2))
d7=A.aR(a6,c,b2.a)
h1=a3&&!a4
a1.b=A.tg(e4,h0,e3,l8.ep(m3,b2,h1),b2,d7)}else if(!a3&&m3.c==null&&m3.d==null&&m3.b.length!==0){c=l8.b
a6=b2.a
d7=A.aR(c,l8.c,a6)
if(b2.at){c=b2.b
h2=c.length
h3=J.dz(h2,t.bv)
for(a7=b2.c,l=0;l<h2;++l)h3[l]=new A.aZ(c[l],a7[l],!1,!1,l9,l9,!1,l9,l9,l9)
c=b2.ax
c.toString
a7=b2.ay
a7.toString
a1.b=new A.hf(new A.dg(a6,h3,c,a7))}else{a6=d7.c+"/"+d7.b+".db"
h4=c.a_(a6).a4()
h5=l8.eo(m3,b2)
if(h4>50)if(c.gab()==null){a7=m3.f
a7=(a7.length!==0?B.b.gH(a7):l9)==null&&m3.as==null
a2=a7}if(a2){c=c.f
a7=m3.r
b0=m3.w==null&&!l8.bP(m3.a)?b3:l9
b5=$.rl()
b6=m3.w
a1.b=new A.dK(a6,b2,c,a7,b0,h4,b5,b6,m3.w!=null||l8.bP(m3.a)?b3:l9)}else{if(m3.ax!=null){q=A.bO(m3.ax.b,A.o(t.N,t.r))
if(q instanceof A.p)h6=q.a
else h6=q instanceof A.j?B.h.be(q.a):A.a3(q.l(0),l9)}else h6=l9
a1.b=A.qi(d7,b2,h5,h6)}}}}}c=b2.Q
if(c.length!==0){e1=B.b.gH(c).b
for(a6=c.length,l=1;l<a6;++l)e1=new A.a0("OR",e1,c[l].b)
a1.b=A.eu(a1.eO(),e1)}h7=a1.eO()
c=t.s
h8=A.a([],c)
for(a6=b2.b,a7=a6.length,b0=b2.a+".",a8=0;a8<a6.length;a6.length===a7||(0,A.n)(a6),++a8){h9=a6[a8]
h8.push(h9)
h8.push(b0+h9)}a6=m3.f.length
if(a6>1)B.b.ar(m3.f,new A.mC(l8))
for(a6=m3.f,a7=a6.length,b0=t.N,b5=t.c,b6=t.b,b7=t.b_,c3=l8.a,i0=l8.b,i1=l8.c,i2=c3.c,i3=t.w,i4=t.d,i5=i1+"/",i6=t.i,i7=t.fY,a8=0;a8<a6.length;a6.length===a7||(0,A.n)(a6),++a8){i8=a6[a8]
i9=i8.b
if(i9!=null){a5=l8.aL(i9)
s=A.a([],c)
r=A.a([],i4)
for(i9=i9.a,j0=i9.length,b8=0;b8<i9.length;i9.length===j0||(0,A.n)(i9),++b8){a9=i9[b8]
j1=a9.b
if(j1!=null)s.push(j1)
else{j1=a9.a
if(j1 instanceof A.I)s.push(B.b.gV(j1.b))
else s.push(A.R(j1))}r.push(B.t)}j2=i8.c
j3=j2==null?"join_subquery":j2
b4=A.bL(l9,l9,l9,s,l9,l9,l9,l9,r,l9,l9,l9,!1,!1,j3,l9,l9,l9,l9,l9,l9)
j4=new A.dU(a5,j2)
j5=j3}else{j5=i8.a.toLowerCase()
j6=i2.h(0,j5.toLowerCase())
if(j6==null)throw A.c(A.q("Join table '"+j5+m2))
i9=j6.d
j0=j6.a
if(i9)j4=A.pN(new A.bS(i0,j0,i1),j6,l8.eq(m3,i8,j6))
else{d7=new A.cp(i0,j0,i1)
d7.d=new A.fk(i0,i1,j0)
j4=A.qi(d7,j6,l8.eq(m3,i8,j6),l9)}b4=j6}i9=b4.Q
if(i9.length!==0){j7=B.b.gH(i9).b
for(j0=i9.length,l=1;l<j0;++l)j7=new A.a0("OR",j7,i9[l].b)
j4=new A.ci(j4,j7)
j4.c=A.K(j7)}j8=i8.d
j9=""
k0=""
if(j8 instanceof A.a0&&j8.b==="="){i9=j8.c
if(i9 instanceof A.I&&j8.d instanceof A.I){k1=i3.a(j8.d)
k2=j5.toLowerCase()
j0=i8.c
k3=j0==null?l9:j0.toLowerCase()
i9=i9.b
k4=i9[0].toLowerCase()
j0=k1.b
k5=j0[0].toLowerCase()
if(k5!==k2)j1=k3!=null&&k5===k3
else j1=!0
if(j1){j9=B.b.S(B.b.ac(i9,1),".")
k0=B.b.S(B.b.ac(j0,1),".")}else{if(k4!==k2)j1=k3!=null&&k4===k3
else j1=!0
if(j1){j9=B.b.S(B.b.ac(j0,1),".")
k0=B.b.S(B.b.ac(i9,1),".")}}}}if(j9.length===0||k0.length===0){h7=new A.hz(h7,j4,j8,i8.e,i8.f,i8.r,A.a6(h8,!0,b0),b4,A.a([],b6),A.aD(b7))
h7.x=A.K(j8)}else{d3=c3.b5(j5,k0)
k6=d3==null?l9:d3.a.toLowerCase()
d9=k6!=null?i5+k6+".idx":l9
k7=!b4.d&&d9!=null
i9=i8.e
j0=i8.f
j1=i8.r
if(k7){k8=b4.a
k9=new A.cp(i0,k8,i1)
k9.d=new A.fk(i0,i1,k8)
d3.toString
h7=new A.dx(h7,k9,A.h1(i0,d9,l8.d4(d3)),j9,b4,i9,j0,j1,A.a6(h8,!0,b0),A.o(i6,i7),A.a([],b6),A.aD(b7))
h7.y=A.K(new A.I(A.a([j9],c)))}else{h7=new A.dw(h7,j4,j9,k0,i9,j0,j1,A.a6(h8,!0,b0),b4,A.o(b0,b5),A.a([],b6),A.aD(b7))
h7.y=A.K(new A.I(A.a([j9],c)))
h7.z=A.K(new A.I(A.a([k0],c)))}}for(i9=b4.b,j0=i9.length,j1=b4.a+".",b8=0;b8<i9.length;i9.length===j0||(0,A.n)(i9),++b8){h9=i9[b8]
h8.push(h9)
h8.push(j1+h9)}}if(m3.as!=null){l0=m3.as.toLowerCase()
l1=c3.d.h(0,l0.toLowerCase())
if(l1==null)throw A.c(A.q("Relationship '"+l0+m0))
l2=l1.c.toLowerCase()
l3=i2.h(0,l2.toLowerCase())
if(l3==null)throw A.c(A.q("Target table '"+l2+"' of relationship '"+l0+m2))
a6=l3.d
a7=l3.a
if(a6){l4=new A.bS(i0,a7,i1)
l5=l9}else{l5=A.aR(i0,i1,a7)
l4=l9}a7=l1.e
d3=c3.b5(l2,a7)
k6=d3==null?l9:d3.a.toLowerCase()
d9=k6!=null?i5+k6+".idx":l9
if(!a6&&d9!=null){d3.toString
l6=A.h1(i0,d9,l8.d4(d3))}else l6=l9
a6=l1.d
h7=new A.dv(h7,l5,l4,l6,a6,a7,l3)
h7.w=A.K(new A.I(A.a([a6],c)))}if(m3.r!=null)c=(!a3||a4)&&!a2
else c=!1
if(c){c=m3.r
c.toString
h7=A.eu(h7,c)}l7=l8.hL(b3)
if(l7.length!==0){if(m3.w!=null&&!a2){c=m3.w
c.toString
h7=new A.bY(h7,c,b3,m3.x)}else if(l8.bP(b3)&&!a2)h7=new A.bY(h7,new A.ag(1),b3,m3.x)
for(c=l7.length,a8=0;a8<c;++a8)h7=new A.i_(h7,l7[a8])
if(m3.w==null&&!l8.bP(b3)&&!a2)h7=A.hK(h7,b3)}else if(m3.w!=null&&!a2){c=m3.w
c.toString
h7=new A.bY(h7,c,b3,m3.x)}else if(l8.bP(b3)&&!a2)h7=new A.bY(h7,new A.ag(1),b3,m3.x)
else if(!a2)h7=A.hK(h7,b3)
if(a2&&m3.x!=null){c=m3.x
c.toString
h7=A.eu(h7,c)}if(m3.at)h7=new A.h9(h7,A.aD(t.Y))
if(m3.y!=null)h7=A.ql(h7,m3.y.a,m3.y.b)
if(m3.z!=null){c=m3.z
c.toString
a6=m3.Q
h7=new A.cP(h7,c,a6==null?0:a6)}return h7},
ep(a,a0,a1){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c=this,b=a.a
if(b.length===1){s=b[0].a
s=s instanceof A.I&&B.b.gH(s.b)==="*"}else s=!1
if(s){r=a0.b.length
q=J.dz(r,t.S)
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
if(m!=null&&m.b.toLowerCase()===a0.a.toLowerCase())o.R(0,m.d)}b=a.e
l=b==null?null:b.toLowerCase()
k=A.aD(t.S)
for(b=A.fz(o,o.r,o.$ti.c),s=a0.b,j=a0.a,i=l!=null,h=b.$ti.c;b.p();){g=b.d
if(g==null)g=h.a(g)
f=g.toLowerCase()
for(p=0;p<s.length;++p){e=s[p].toLowerCase()
g=!0
if(f!==e)if(f!==j.toLowerCase()+"."+e){if(i){g=l+"."+e
g=f===g||B.a.U(f,g+".")}else g=!1
g=g||B.a.U(f,e+".")||B.a.U(f,j.toLowerCase()+"."+e+".")}if(g)k.R(0,p)}}if(k.a===0){if(a1)return A.a([],t.t)
return A.a([0],t.t)}d=A.r(k,k.$ti.c)
B.b.dR(d)
return d},
eo(a,b){return this.ep(a,b,!1)},
eq(a,b,c){var s,r,q,p,o,n,m,l,k,j,i,h,g=this,f=A.aD(t.N)
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
for(s=A.fz(f,f.r,f.$ti.c),r=c.b,n=c.a,m=p!=null,l=s.$ti.c;s.p();){k=s.d
if(k==null)k=l.a(k)
j=k.toLowerCase()
for(i=0;i<r.length;++i){h=r[i].toLowerCase()
k=!0
if(j!==h)if(j!==n.toLowerCase()+"."+h){if(m){k=p+"."+h
k=j===k||B.a.U(j,k+".")}else k=!1
k=k||B.a.U(j,h+".")||B.a.U(j,n.toLowerCase()+"."+h+".")}if(k)o.R(0,i)}}if(o.a===0)return A.a([0],t.t)
s=A.r(o,o.$ti.c)
B.b.dR(s)
return s},
af(a,b){var s,r,q,p,o=this
if(a instanceof A.I)b.R(0,B.b.S(a.b,"."))
else if(a instanceof A.b9)o.af(a.b,b)
else if(a instanceof A.a0){o.af(a.c,b)
o.af(a.d,b)}else if(a instanceof A.af)for(s=a.c,r=s.length,q=0;q<s.length;s.length===r||(0,A.n)(s),++q)o.af(s[q],b)
else if(a instanceof A.bM){for(s=a.d,r=s.length,q=0;q<s.length;s.length===r||(0,A.n)(s),++q)o.af(s[q],b)
s=a.e
if(s!=null)o.af(s.a,b)}else if(a instanceof A.dd){for(s=a.b,r=s.length,q=0;q<s.length;s.length===r||(0,A.n)(s),++q){p=s[q]
o.af(p.a,b)
o.af(p.b,b)}s=a.c
if(s!=null)o.af(s,b)}},
bP(a){var s,r
for(s=a.length,r=0;r<s;++r)if(this.ca(a[r].a))return!0
return!1},
ca(a){var s
if(a instanceof A.af){s=a.b.toLowerCase()
if(s==="count"||s==="sum"||s==="avg"||s==="min"||s==="max")return!0}if(a instanceof A.b9)return this.ca(a.b)
if(a instanceof A.a0)return this.ca(a.c)||this.ca(a.d)
return!1},
is(a,b){var s,r,q,p,o
if(a instanceof A.a0)if(a.b.toUpperCase()==="AND"){s=this.dm(a.c,b)
r=this.dm(a.d,b)
if(s!=null&&r!=null&&s.a===r.a){q=s.a
p=s.b
if(p==null)p=r.b
o=s.c
return new A.bi(q,p,o==null?r.c:o)}}else return this.dm(a,b)
return null},
ce(a){if(a instanceof A.ag)return a.b
a instanceof A.aQ
return null},
dm(a,b){var s,r,q,p,o,n=this,m=null
if(a instanceof A.a0){s=a.b
r=a.c
q=a.d
if(q instanceof A.ag||q instanceof A.aQ){p=n.bS(A.R(r),b)
o=n.ce(q)
if(typeof o=="number"){if(s==="=")return new A.bi(p,o,o)
if(s===">=")return new A.bi(p,o,m)
if(s===">")return new A.bi(p,o+0.000001,m)
if(s==="<=")return new A.bi(p,m,o)
if(s==="<")return new A.bi(p,m,o-0.000001)}}else if(r instanceof A.ag||r instanceof A.aQ){p=n.bS(A.R(q),b)
o=n.ce(r)
if(typeof o=="number"){if(s==="=")return new A.bi(p,o,o)
if(s==="<=")return new A.bi(p,o,m)
if(s==="<")return new A.bi(p,o+0.000001,m)
if(s===">=")return new A.bi(p,m,o)
if(s===">")return new A.bi(p,m,o-0.000001)}}}return m},
ig(a){var s,r,q,p,o,n,m,l,k,j=null,i=a.e,h=i==null?j:i.toLowerCase(),g=a.f,f=g.length!==0?B.b.gH(g):j
if(f==null)s=j
else{f=f.c
s=f==null?j:f.toLowerCase()}f=new A.mu(this,h,a,s)
r=a.a
q=A.z(r).i("h<1,ai>")
p=A.r(new A.h(r,new A.mt(f),q),q.i("u.E"))
if((g.length!==0?B.b.gH(g):j)!=null){r=(g.length!==0?B.b.gH(g):j).a
q=f.$1((g.length!==0?B.b.gH(g):j).d)
o=new A.bp(r,j,(g.length!==0?B.b.gH(g):j).c,q,!1,!1,!1)}else o=j
g=a.r
n=g!=null?f.$1(g):j
g=a.w
m=g!=null?f.$1(g):j
g=a.x
l=g!=null?f.$1(g):j
g=a.y
k=g!=null?new A.dH(f.$1(g.a),g.b):j
return A.p2(j,a.d,a.c,m,l,!1,o,j,a.z,j,k,p,i,a.b,n,a.as)},
j4(a,b){var s,r,q,p,o,n,m,l,k,j,i,h,g,f=null,e=this.a,d=e.c.h(0,a.toLowerCase())
if(d==null)return f
for(e=J.au(e.bu(a)),s=t.s,r=t.e,q=r.i("u.E"),p=f,o=p,n=o,m=-1;e.p();){l=e.gF()
k=l.c
if(B.b.cq(A.a(k.split(","),s),new A.mw(d)))j=A.r(new A.h(A.a(k.split(","),s),new A.mx(),r),q)
else j=A.a([k.toLowerCase()],s)
if(j.length===0)continue
i=this.ej(b,a,j)
if(i!=null){h=i[0]
g=h.length
if(g>m){p=i[1]
m=g
o=h
n=l}}}if(n!=null)return new A.jK(n,o,p)
return f},
ej(a,b,c){var s,r,q,p,o=t.n,n=A.a([],o),m=A.a([],o)
for(s=0;s<c.length;++s){r=B.a.W(c[s]).toLowerCase()
q=this.d3(a,b,r)
if(q!=null){n.push(q)
m.push(q)}else if(s===0){p=this.is(a,b)
if(p!=null&&p.a===r){o=p.b
if(o!=null)n.push(o)
o=p.c
if(o!=null)m.push(o)
break}else return null}else break}return A.a([n,m],t.gy)},
d3(a,b,c){var s,r,q,p,o,n=this
if(a instanceof A.a0){s=a.b.toUpperCase()
if(s==="AND"){r=n.d3(a.c,b,c)
if(r!=null)return r
return n.d3(a.d,b,c)}else if(s==="="){q=a.c
p=a.d
o=n.bS(c,b)
if(p instanceof A.ag||p instanceof A.aQ)if(n.bS(A.R(q),b)===o)return n.e9(n.ce(p))
if(q instanceof A.ag||q instanceof A.aQ)if(n.bS(A.R(p),b)===o)return n.e9(n.ce(q))}}return null},
e9(a){var s,r,q,p
if(typeof a=="number")return a
if(typeof a=="string"){s=A.aH(a)
if(s!=null)return s
for(r=a.length,q=0,p=0;p<r;++p)q=B.c.a7(q*31+a.charCodeAt(p),9007199254740991)
return q}return null},
hL(a){var s,r,q=A.a([],t.fu)
for(s=a.length,r=0;r<a.length;a.length===s||(0,A.n)(a),++r)this.c7(a[r].a,q)
return q},
c7(a,b){var s,r,q
if(a instanceof A.bM)b.push(a)
else if(a instanceof A.a0){this.c7(a.c,b)
this.c7(a.d,b)}else if(a instanceof A.af)for(s=a.c,r=s.length,q=0;q<s.length;s.length===r||(0,A.n)(s),++q)this.c7(s[q],b)},
cg(a,b){var s,r,q,p,o,n,m,l,k,j,i=a.b,h=i.toLowerCase(),g=a.c
if(b.D(h)){g=b.h(0,h)
s=a.e
i=s==null?i:s}if(g!=null)g=this.cg(g,b)
r=A.a([],t.R)
for(q=a.f,p=q.length,o=0;o<q.length;q.length===p||(0,A.n)(q),++o){n=q[o]
m=n.a
l=m.toLowerCase()
k=n.b
if(b.D(l)){k=b.h(0,l)
j=n.c
m=j==null?m:j}if(k!=null)k=this.cg(k,b)
r.push(new A.bp(m,k,n.c,n.d,n.e,n.f,n.r))}return A.p2(null,a.d,g,a.w,a.x,a.at,null,r,a.z,a.Q,a.y,a.a,a.e,i,a.r,a.as)},
i9(a,b,c,d){var s,r=new A.hL(this.aL(b),new A.ms(c,d)),q=a.ch,p=q.r,o=p!=null?A.eu(r,p):r
p=q.a
if(p.length!==0)o=A.hK(o,p)
p=q.y
if(p!=null)o=A.ql(o,p.a,p.b)
p=q.z
s=p==null
if(!s||q.Q!=null){if(s)p=-1
s=q.Q
o=new A.cP(o,p,s==null?0:s)}return o}}
A.mp.prototype={
$1(a){var s,r,q,p=this
if(a instanceof A.I){s=a.b
if(s.length===1){r=B.b.gH(s).toLowerCase()
s=p.a
if(s.D(r)){s=s.h(0,r)
s.toString
return s}}return a}if(a instanceof A.a0)return new A.a0(a.b,p.$1(a.c),p.$1(a.d))
if(a instanceof A.af){s=a.c
q=A.z(s).i("h<1,M>")
s=A.r(new A.h(s,p,q),q.i("u.E"))
return new A.af(a.b,s)}if(a instanceof A.b9)return new A.b9(p.$1(a.b),a.c,a.d)
return a},
$S:45}
A.mr.prototype={
$1(a){var s,r,q,p
if(!B.a.U(a,"(")||!B.a.B(a,")"))return!1
for(s=a.length-1,r=0,q=0;q<s;++q){p=a[q]
if(p==="(")++r
else if(p===")")--r
if(r===0)return!1}return r===1},
$S:8}
A.mq.prototype={
$1(a){var s=this.a.dx
s===$&&A.b()
return B.b.E(s,B.a.W(a).toLowerCase())},
$S:8}
A.mE.prototype={
$1(a){return this.a.aL(a)},
$S:29}
A.my.prototype={
$1(a){return this.a.aL(a)},
$S:29}
A.mv.prototype={
$1(a){return this.a.aL(a)},
$S:29}
A.mz.prototype={
$1(a){return A.cA(B.a.W(a))},
$S:9}
A.mA.prototype={
$1(a){return B.a.W(a).toLowerCase()},
$S:7}
A.mB.prototype={
$1(a){return B.a.W(a).toLowerCase()},
$S:7}
A.mC.prototype={
$2(a,b){var s=new A.mD(this.a)
return J.pB(s.$1(a),s.$1(b))},
$S:91}
A.mD.prototype={
$1(a){var s,r,q,p,o,n=a.a.toLowerCase(),m=this.a.a.f.h(0,n.toLowerCase())
if(m==null)return 1e4
s=a.d
if(s instanceof A.a0&&s.b==="="){r=s.c
if(r instanceof A.I&&B.b.gH(r.b).toLowerCase()===n)q=B.b.gV(r.b).toLowerCase()
else{s=s.d
q=s instanceof A.I&&B.b.gH(s.b).toLowerCase()===n?B.b.gV(s.b).toLowerCase():""}}else q=""
s=q.length!==0
if(s&&m.c.D(q))p=m.c.h(0,q).ix(0)
else if(s&&m.b.D(q)){o=m.b.h(0,q).c
p=o>0?1/o:0.1}else p=0.1
return m.a*p},
$S:92}
A.mu.prototype={
$1(a){var s,r,q,p,o,n=this
if(a instanceof A.I){s=a.b
if(s.length!==0){r=B.b.gH(s).toLowerCase()
q=n.b
if(q!=null&&r===q){q=A.a([n.c.b],t.s)
B.b.X(q,B.b.ac(s,1))
return new A.I(q)}q=n.d
if(q!=null&&r===q){q=n.c.f
q=A.a([(q.length!==0?B.b.gH(q):null).a],t.s)
B.b.X(q,B.b.ac(s,1))
return new A.I(q)}}return a}if(a instanceof A.b9)return new A.b9(n.$1(a.b),a.c,a.d)
if(a instanceof A.a0)return new A.a0(a.b,n.$1(a.c),n.$1(a.d))
if(a instanceof A.af){s=n.a
q=a.b
p=s.d.$1(q)
if(p!=null){q=a.c
o=A.z(q).i("h<1,M>")
q=A.r(new A.h(q,n,o),o.i("u.E"))
return n.$1(s.hH(p,q))}s=a.c
o=A.z(s).i("h<1,M>")
s=A.r(new A.h(s,n,o),o.i("u.E"))
return new A.af(q,s)}if(a instanceof A.bM){s=a.d
q=A.z(s).i("h<1,M>")
s=A.r(new A.h(s,n,q),q.i("u.E"))
q=a.e
q=q!=null?new A.dH(n.$1(q.a),q.b):null
return new A.bM(a.b,B.cJ,s,q)}return a},
$S:45}
A.mt.prototype={
$1(a){return new A.ai(this.a.$1(a.a),a.b)},
$S:93}
A.mw.prototype={
$1(a){var s=this.a.dx
s===$&&A.b()
return B.b.E(s,B.a.W(a).toLowerCase())},
$S:8}
A.mx.prototype={
$1(a){return B.a.W(a).toLowerCase()},
$S:7}
A.ms.prototype={
$1(a){var s=this.a,r=s.r,q=r!=null?A.eu(a,r):a
s=s.a
return s.length!==0?A.hK(q,s):q},
$S:94}
A.bi.prototype={}
A.jK.prototype={}
A.j7.prototype={
am(){var s=this,r=s.f,q=A.z(r).i("h<1,w<e,@>>")
r=A.r(new A.h(r,new A.j8(),q),q.i("u.E"))
return A.a7(["sql",s.a,"totalDurationMicroseconds",s.b,"rowsReturned",s.c,"cacheHitRatePercentage",s.d,"peakMemoryBytes",s.e,"steps",r],t.N,t.z)}}
A.j8.prototype={
$1(a){return a.am()},
$S:95}
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
return!0}if(n instanceof A.L&&b instanceof A.L)return n.l(0)===b.gaP()
if(n instanceof A.aG&&b instanceof A.aG)return n.a===b.a
if(n instanceof A.bn&&b instanceof A.bn)return n.a===b.a
if(n instanceof A.bm&&b instanceof A.bm)return n.a.aw(0,b.a)
if(n instanceof A.b_&&b instanceof A.b_)return n.a===b.a
if(n instanceof A.a8&&b instanceof A.a8)return n.a===b.a
return!1},
gY(a){var s,r,q=this
if(q instanceof A.d)return 0
if(q instanceof A.p)return B.c.gY(q.a)
if(q instanceof A.j)return B.h.gY(q.a)
if(q instanceof A.m)return B.a.gY(q.a)
if(q instanceof A.a5){for(s=J.au(q.a),r=17;s.p();)r=37*r+J.by(s.gF())
return r}if(q instanceof A.L)return B.a.gY(q.l(0))
if(q instanceof A.aG)return B.cC.gY(q.a)
if(q instanceof A.bn)return B.a.gY(q.a)
if(q instanceof A.bm)return q.a.gY(0)
if(q instanceof A.b_)return B.j.gY(q.a)
if(q instanceof A.a8)return B.h.gY(q.a)
return 0}}
A.j0.prototype={
$1(a){return typeof a=="number"},
$S:96}
A.j1.prototype={
$1(a){return A.ir(a)},
$S:97}
A.d.prototype={
gae(){return B.t},
ga2(){return null},
al(){var s=new Uint8Array(1)
s[0]=0
return s},
A(a,b){if(b instanceof A.d)return 0
return-1},
aq(a,b){return new A.d()},
aH(a,b){return new A.d()},
P(a,b){return new A.d()},
aE(a,b){return new A.d()},
aJ(a){return new A.d()},
l(a){return"NULL"}}
A.p.prototype={
gae(){return B.aw},
al(){var s,r,q,p=null,o=this.a
if(o>=-128&&o<=127){s=new Uint8Array(2)
s[0]=1
r=A.aq(s,0,p)
r.$flags&2&&A.i(r,6)
r.setInt8(1,o)
return s}else if(o>=-32768&&o<=32767){s=new Uint8Array(3)
q=A.aq(s,0,p)
q.$flags&2&&A.i(q,9)
q.setUint8(0,1)
q.setInt16(1,o,!1)
return s}else if(o>=-2147483648&&o<=2147483647){s=new Uint8Array(5)
q=A.aq(s,0,p)
q.$flags&2&&A.i(q,9)
q.setUint8(0,1)
q.setInt32(1,o,!1)
return s}else{q=A.aq(new Uint8Array(9),0,p)
q.$flags&2&&A.i(q,9)
q.setUint8(0,1)
B.r.c2(q,1,o)}},
A(a,b){if(b instanceof A.d)return 1
if(b instanceof A.p)return B.c.A(this.a,b.a)
if(b instanceof A.j)return B.c.A(this.a,b.a)
return B.a.A(B.c.l(this.a),b.l(0))},
aq(a,b){if(b instanceof A.p)return A.v(this.a+b.a)
if(b instanceof A.j)return new A.j(this.a+b.a)
return new A.d()},
aH(a,b){if(b instanceof A.p)return A.v(this.a-b.a)
if(b instanceof A.j)return new A.j(this.a-b.a)
return new A.d()},
P(a,b){if(b instanceof A.p)return A.v(this.a*b.a)
if(b instanceof A.j)return new A.j(this.a*b.a)
return new A.d()},
aE(a,b){if(b instanceof A.p)return new A.j(this.a/b.a)
if(b instanceof A.j)return new A.j(this.a/b.a)
return new A.d()},
aJ(a){return new A.m(B.c.l(this.a)+a.l(0))},
l(a){return B.c.l(this.a)},
ga2(){return this.a}}
A.j.prototype={
gae(){return B.L},
al(){var s=new Uint8Array(9),r=A.aq(s,0,null)
r.$flags&2&&A.i(r,9)
r.setUint8(0,2)
r.setFloat64(1,this.a,!1)
return s},
A(a,b){if(b instanceof A.d)return 1
if(b instanceof A.p)return B.h.A(this.a,b.a)
if(b instanceof A.j)return B.h.A(this.a,b.a)
return B.a.A(B.h.l(this.a),b.l(0))},
aq(a,b){if(b instanceof A.p)return new A.j(this.a+b.a)
if(b instanceof A.j)return new A.j(this.a+b.a)
return new A.d()},
aH(a,b){if(b instanceof A.p)return new A.j(this.a-b.a)
if(b instanceof A.j)return new A.j(this.a-b.a)
return new A.d()},
P(a,b){if(b instanceof A.p)return new A.j(this.a*b.a)
if(b instanceof A.j)return new A.j(this.a*b.a)
return new A.d()},
aE(a,b){if(b instanceof A.p)return new A.j(this.a/b.a)
if(b instanceof A.j)return new A.j(this.a/b.a)
return new A.d()},
aJ(a){return new A.m(B.h.l(this.a)+a.l(0))},
l(a){return B.h.l(this.a)},
ga2(){return this.a}}
A.m.prototype={
gae(){return B.t},
al(){var s=B.x.aC(this.a),r=new Uint8Array(1+s.length)
r[0]=3
B.j.aj(r,1,s)
return r},
A(a,b){if(b instanceof A.d)return 1
return B.a.A(this.a,b.l(0))},
aq(a,b){return new A.m(this.a+b.l(0))},
aH(a,b){return new A.d()},
P(a,b){return new A.d()},
aE(a,b){return new A.d()},
aJ(a){return new A.m(this.a+a.l(0))},
l(a){return this.a},
ga2(){return this.a}}
A.a5.prototype={
gae(){return B.W},
al(){var s,r=this.a,q=J.X(r),p=q.gt(r),o=new Uint8Array(1+p*8),n=A.aq(o,0,null)
n.$flags&2&&A.i(n,9)
n.setUint8(0,4)
for(s=0;s<q.gt(r);++s)n.setFloat64(1+s*8,q.h(r,s),!1)
return o},
A(a,b){if(b instanceof A.d)return 1
return B.a.A("["+J.oy(this.a,", ")+"]",b.l(0))},
aq(a,b){return new A.d()},
aH(a,b){return new A.d()},
P(a,b){return new A.d()},
aE(a,b){return new A.d()},
aJ(a){return new A.d()},
l(a){return"["+J.oy(this.a,", ")+"]"},
cm(a){var s,r,q,p,o,n,m,l,k,j=this.a,i=a.a,h=J.X(j),g=h.gt(j),f=J.X(i)
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
cl(a3){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b=this.a,a=a3.a,a0=J.X(b),a1=a0.gt(b),a2=J.X(a)
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
cn(a){var s,r,q,p,o,n,m=this.a,l=a.a,k=J.X(m),j=k.gt(m),i=J.X(l)
if(j!==i.gt(l)||j===0)return 0
s=j-3
for(r=0,q=0;q<s;q+=4){p=q+1
o=q+2
n=q+3
r+=k.h(m,q)*i.h(l,q)+k.h(m,p)*i.h(l,p)+k.h(m,o)*i.h(l,o)+k.h(m,n)*i.h(l,n)}for(;q<j;++q)r+=k.h(m,q)*i.h(l,q)
return-r},
ga2(){return this.a}}
A.L.prototype={
gae(){return B.M},
gaP(){var s=this,r=s.b
if(r==null){r=s.c
if(r!=null){r=B.a5.ag(r)
s.b=r}else{r=B.o.bC(s.a)
s.b=r}}return r},
ga2(){var s=this.a
return s==null?this.a=B.o.ag(this.gaP()):s},
al(){var s,r,q,p=this.c
if(p!=null){s=p.length
r=new Uint8Array(1+s)
r[0]=5
B.j.aj(r,1,p)
return r}q=B.x.aC(this.gaP())
r=new Uint8Array(1+q.length)
r[0]=5
B.j.aj(r,1,q)
return r},
A(a,b){if(b instanceof A.d)return 1
return B.a.A(this.gaP(),b.l(0))},
aV(a){if(this.a==null)return A.w4(this.gaP(),a)
return this.ek(a)},
ek(a){var s,r,q,p,o,n,m=this.ga2()
for(s=a.length,r=t.j,q=t.f,p=0;p<a.length;a.length===s||(0,A.n)(a),++p){o=a[p]
if(q.b(m)&&m.D(o))m=m.h(0,o)
else if(r.b(m)){n=A.a3(o,null)
if(n!=null&&n>=0&&n<J.O(m))m=J.a_(m,n)
else return new A.d()}else return new A.d()}return A.cg(m)},
aq(a,b){return new A.d()},
aH(a,b){return new A.d()},
P(a,b){return new A.d()},
aE(a,b){return new A.d()},
aJ(a){return new A.d()},
l(a){return this.gaP()}}
A.aN.prototype={
h(a,b){var s
if(typeof b=="string"){s=this.b.h(0,b)
if(s!=null&&s<this.a.length)return this.a[s]}return null},
k(a,b,c){var s,r=this.b.h(0,b)
if(r!=null&&r<this.a.length){s=this.a
s.$flags&2&&A.i(s)
s[r]=c}},
gZ(){return this.b.gZ()},
T(a,b){return null},
gaO(){return this.a}}
A.aO.prototype={
gae(){return B.M},
ga2(){return this.a},
al(){return new Uint8Array(0)},
A(a,b){var s,r,q,p,o,n
if(b instanceof A.aO){s=this.a
r=s.length
q=b.a
p=q.length
if(r!==p)return B.c.A(r,p)
for(o=0;o<s.length;++o){n=s[o].A(0,q[o])
if(n!==0)return n}return 0}return-1},
aq(a,b){return new A.d()},
aH(a,b){return new A.d()},
P(a,b){return new A.d()},
aE(a,b){return new A.d()},
aJ(a){return new A.d()},
l(a){var s=this.a
return"["+new A.h(s,new A.j_(),A.z(s).i("h<1,e>")).S(0,", ")+"]"}}
A.j_.prototype={
$1(a){return a.l(0)},
$S:18}
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
aq(a,b){return new A.d()},
aH(a,b){return new A.d()},
P(a,b){return new A.d()},
aE(a,b){return new A.d()},
aJ(a){var s=this.a?"true":"false"
return new A.m(s+a.l(0))},
l(a){return this.a?"true":"false"},
ga2(){return this.a}}
A.bn.prototype={
gae(){return B.a7},
al(){var s=B.x.aC(this.a),r=new Uint8Array(1+s.length)
r[0]=9
B.j.aj(r,1,s)
return r},
A(a,b){if(b instanceof A.bn)return B.a.A(this.a,b.a)
return B.a.A(this.a,b.l(0))},
aq(a,b){return new A.d()},
aH(a,b){return new A.d()},
P(a,b){return new A.d()},
aE(a,b){return new A.d()},
aJ(a){return new A.m(this.a+a.l(0))},
l(a){return this.a},
ga2(){return this.a}}
A.bm.prototype={
gae(){return B.a8},
al(){var s=new DataView(new ArrayBuffer(9))
s.setUint8(0,10)
B.r.c2(s,1,this.a.a)},
A(a,b){var s
if(b instanceof A.bm)return this.a.A(0,b.a)
if(b instanceof A.m){s=A.bA(b.a)
if(s!=null)return this.a.A(0,s)}return B.a.A(this.a.bs(),b.l(0))},
aq(a,b){return new A.d()},
aH(a,b){return new A.d()},
P(a,b){return new A.d()},
aE(a,b){return new A.d()},
aJ(a){return new A.m(this.a.bs()+a.l(0))},
l(a){return this.a.bs()},
ga2(){return this.a}}
A.b_.prototype={
gae(){return B.a9},
al(){var s=this.a,r=new Uint8Array(1+s.length)
r[0]=11
B.j.aj(r,1,s)
return r},
A(a,b){var s,r,q,p,o,n,m
if(b instanceof A.b_){s=this.a
r=s.length
q=b.a
p=q.length
o=Math.min(r,p)
for(n=0;n<o;++n){m=B.c.A(s[n],q[n])
if(m!==0)return m}return B.c.A(r,p)}return-1},
aq(a,b){return new A.d()},
aH(a,b){return new A.d()},
P(a,b){return new A.d()},
aE(a,b){return new A.d()},
aJ(a){var s,r,q,p
if(a instanceof A.b_){s=this.a
r=s.length
q=a.a
p=new Uint8Array(r+q.length)
B.j.aj(p,0,s)
B.j.aj(p,r,q)
return new A.b_(p)}return new A.d()},
l(a){var s=this.a
return"X'"+new A.h(s,new A.iZ(),A.bQ(s).i("h<a2.E,e>")).dE(0)+"'"},
ga2(){return this.a}}
A.iZ.prototype={
$1(a){return B.a.a0(B.c.fA(a,16),2,"0")},
$S:5}
A.a8.prototype={
gae(){return B.aa},
al(){var s=new DataView(new ArrayBuffer(9))
s.setUint8(0,12)
s.setFloat64(1,this.a,!1)
return J.ox(B.r.gai(s))},
A(a,b){var s,r=this
if(b instanceof A.a8)return B.h.A(r.a,b.a)
if(b instanceof A.p)return B.h.A(r.a,b.a)
if(b instanceof A.j)return B.h.A(r.a,b.a)
s=A.aH(b.l(0))
if(s==null)s=0
return B.h.A(r.a,s)},
aq(a,b){if(b instanceof A.a8)return new A.a8(this.a+b.a)
if(b instanceof A.p)return new A.a8(this.a+b.a)
if(b instanceof A.j)return new A.a8(this.a+b.a)
return new A.d()},
aH(a,b){if(b instanceof A.a8)return new A.a8(this.a-b.a)
if(b instanceof A.p)return new A.a8(this.a-b.a)
if(b instanceof A.j)return new A.a8(this.a-b.a)
return new A.d()},
P(a,b){if(b instanceof A.a8)return new A.a8(this.a*b.a)
if(b instanceof A.p)return new A.a8(this.a*b.a)
if(b instanceof A.j)return new A.a8(this.a*b.a)
return new A.d()},
aE(a,b){if(b instanceof A.a8)return new A.a8(this.a/b.a)
if(b instanceof A.p)return new A.a8(this.a/b.a)
if(b instanceof A.j)return new A.a8(this.a/b.a)
return new A.d()},
aJ(a){return new A.m(B.h.l(this.a)+a.l(0))},
l(a){return B.h.l(this.a)},
ga2(){return this.a}}
A.av.prototype={
c9(){return"DataType."+this.b}}
A.y.prototype={}
A.M.prototype={}
A.ag.prototype={}
A.aQ.prototype={}
A.I.prototype={}
A.a0.prototype={}
A.af.prototype={}
A.bM.prototype={}
A.cv.prototype={}
A.b9.prototype={}
A.cs.prototype={}
A.dR.prototype={}
A.dn.prototype={}
A.cJ.prototype={}
A.e7.prototype={}
A.aZ.prototype={}
A.ai.prototype={}
A.bp.prototype={}
A.dH.prototype={}
A.G.prototype={}
A.hY.prototype={}
A.hD.prototype={}
A.hE.prototype={}
A.dk.prototype={}
A.dg.prototype={}
A.eI.prototype={}
A.db.prototype={
c9(){return"AlterAction."+this.b}}
A.bR.prototype={}
A.cL.prototype={}
A.dp.prototype={}
A.fo.prototype={}
A.aS.prototype={
giU(a){var s=this.f
return s.length!==0?B.b.gH(s):null}}
A.dm.prototype={}
A.cW.prototype={}
A.dy.prototype={}
A.dr.prototype={}
A.hZ.prototype={}
A.h7.prototype={}
A.ch.prototype={}
A.dL.prototype={}
A.e9.prototype={}
A.ha.prototype={}
A.ez.prototype={}
A.fr.prototype={}
A.ek.prototype={}
A.ea.prototype={}
A.ee.prototype={}
A.f3.prototype={}
A.ey.prototype={}
A.f1.prototype={}
A.f8.prototype={}
A.f7.prototype={}
A.ei.prototype={}
A.fp.prototype={}
A.dj.prototype={}
A.dh.prototype={}
A.du.prototype={}
A.es.prototype={}
A.dc.prototype={}
A.fc.prototype={}
A.fa.prototype={}
A.di.prototype={}
A.hC.prototype={}
A.cG.prototype={}
A.cF.prototype={}
A.ec.prototype={}
A.f_.prototype={}
A.dQ.prototype={}
A.f6.prototype={}
A.f2.prototype={}
A.eZ.prototype={}
A.eQ.prototype={}
A.et.prototype={}
A.ed.prototype={}
A.dl.prototype={}
A.dX.prototype={}
A.dd.prototype={}
A.ce.prototype={}
A.em.prototype={}
A.cH.prototype={}
A.f9.prototype={}
A.fb.prototype={}
A.eS.prototype={}
A.fl.prototype={}
A.el.prototype={}
A.ew.prototype={}
A.cf.prototype={}
A.ej.prototype={}
A.eo.prototype={}
A.og.prototype={
$1(a){return"("+J.bG(a,A.iu(),t.N).S(0,", ")+")"},
$S:98}
A.c1.prototype={
hW(){var s=this.b+1,r=this.a
return s>=r.length?"":r[s]},
ah(){var s,r=this,q=r.b,p=r.a
if(q>=p.length)return""
r.b=q+1
s=p[q]
if(s==="\n"){++r.c
r.d=1}else ++r.d
return s},
bt(){var s,r,q=this,p=A.a([],t.aT)
for(s=q.a.length;q.b<s;){r=q.hZ()
p.push(r)
if(r.a===B.k)break}if(p.length===0||B.b.gV(p).a!==B.k)p.push(new A.N(B.k,"",q.c,q.d))
return p},
hZ(){var s,r,q,p,o,n,m,l,k,j,i=this
i.iq()
s=i.a
r=s.length
if(i.b>=r)return new A.N(B.k,"",i.c,i.d)
q=i.c
p=i.d
o=i.ah()
if(i.ev(o)){n=o
for(;;){m=i.b
m=m>=r?"":s[m]
if(!(i.ev(m)||i.bz(m)))break
n+=i.ah()}l=n.charCodeAt(0)==0?n:n
k=B.cK.h(0,l.toLowerCase())
return new A.N(k==null?B.d:k,l,q,p)}if(i.bz(o)){n=o
for(;;){m=i.b
if(!i.bz(m>=r?"":s[m]))break
n+=i.ah()}m=i.b
if((m>=r?"":s[m])==="."&&i.bz(i.hW())){n+=i.ah()
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
case"]":return new A.N(B.aY,"]",q,p)
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
case"=":return new A.N(B.D,"=",q,p)
case"<":n=i.b
r=n>=r
if((r?"":s[n])==="="){i.ah()
return new A.N(B.cf,"<=",q,p)}else if((r?"":s[n])===">"){i.ah()
return new A.N(B.aW,"<>",q,p)}return new A.N(B.cd,"<",q,p)
case">":n=i.b
if((n>=r?"":s[n])==="="){i.ah()
return new A.N(B.cg,">=",q,p)}return new A.N(B.ce,">",q,p)
case"!":n=i.b
if((n>=r?"":s[n])==="="){i.ah()
return new A.N(B.aW,"!=",q,p)}return new A.N(B.K,"!",q,p)
case":":n=i.b
r=n>=r
if((r?"":s[n])==="="){i.ah()
return new A.N(B.at,":=",q,p)}else if((r?"":s[n])===":"){i.ah()
return new A.N(B.cl,"::",q,p)}return new A.N(B.K,":",q,p)
case"|":n=i.b
if((n>=r?"":s[n])==="|"){i.ah()
return new A.N(B.ch,"||",q,p)}return new A.N(B.K,"|",q,p)
case"~":return new A.N(B.bO,"~",q,p)
case"?":return new A.N(B.aZ,"?",q,p)
case"$":n=o
for(;;){m=i.b
if(!i.bz(m>=r?"":s[m]))break
n+=i.ah()}if(n.length>1)return new A.N(B.aZ,n.charCodeAt(0)==0?n:n,q,p)
return new A.N(B.K,"$",q,p)}return new A.N(B.K,o,q,p)},
iq(){var s,r,q,p,o,n=this
for(s=n.a,r=s.length;q=n.b,p=q>=r,!p;){o=p?"":s[q]
if(o===" "||o==="\r"||o==="\t"||o==="\n")n.ah()
else{if(o==="-"){++q
q=(q>=r?"":s[q])==="-"}else q=!1
if(q)for(;;){q=n.b
p=q>=r
if(!((p?"":s[q])!=="\n"&&!p))break
n.ah()}else break}}},
ev(a){var s,r
if(a.length===0)return!1
s=a.charCodeAt(0)
if(!(s>=65&&s<=90))r=s>=97&&s<=122||s===95
else r=!0
return r},
bz(a){var s
if(a.length===0)return!1
s=a.charCodeAt(0)
return s>=48&&s<=57}}
A.c3.prototype={
bT(){return this.a[this.b]},
aT(){var s=this.b+1,r=this.a
return s<r.length?r[s]:B.b.gV(r)},
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
throw A.c(A.q("["+this.bT().l(0)+"] "+b))},
cb(a){var s=this
if(s.n(B.d)&&s.a[s.b].b.toLowerCase()===a){s.q()
return!0}return!1},
e1(){var s=this.b+1,r=this.a
if(s>=r.length)return!1
s=r[s]
return s.a===B.e||s.b.toLowerCase()==="transaction"},
e0(){var s,r=this.b+1,q=this.a
if(r>=q.length)return!1
r=q[r]
s=r.a
return s===B.H||s===B.S||s===B.I||s===B.am||s===B.an||B.cR.E(0,r.b.toLowerCase())},
fs(){var s,r,q,p=this,o=A.a([],t.m)
for(s=p.a,r=t.B;s[p.b].a!==B.k;){if(!p.n(B.Q))q=p.n(B.w)&&p.e1()
else q=!0
if(q)if(p.n(B.Q))o.push(p.dh())
else o.push(p.eJ())
else if(p.n(B.w))o.push(p.dh())
else o.push(p.av())
while(p.m(A.a([B.e],r)));}return o},
dI(){var s=this.fs()
if(s.length===0)throw A.c(A.q("No statements found in script."))
return B.b.gH(s)},
dh(){var s,r,q,p,o,n,m,l,k=this,j=A.a([],t.a4),i=A.a([],t.aF),h=t.B
if(k.m(A.a([B.Q],h))){s=k.a
for(;;){if(!(!k.n(B.w)&&s[k.b].a!==B.k))break
if(k.n(B.d))if(k.aT().a===B.aF){r=k.j(B.d,"Expected cursor name.")
k.j(B.aF,"Expected 'CURSOR' keyword.")
k.j(B.X,"Expected 'FOR' after 'CURSOR'.")
k.j(B.v,"Expected 'SELECT' for cursor query.")
q=k.bn()
if(k.n(B.e)){p=k.b
if(s[p].a!==B.k)k.b=p+1}i.push(new A.h7(r.b,q))}else if(k.e0())j.push(k.eE())
else break
else break}}s=t.m
if(k.n(B.w)){k.j(B.w,"Expected 'BEGIN' to start executable block.")
o=A.a([],s)
p=k.a
for(;;){if(!(!k.n(B.p)&&!k.n(B.aH)&&p[k.b].a!==B.k))break
o.push(k.av())}if(k.m(A.a([B.aH],h))){n=A.a([],t.aY)
for(;;){if(!(!k.n(B.p)&&p[k.b].a!==B.k))break
k.j(B.ad,"Expected 'WHEN' in EXCEPTION block.")
m=k.j(B.d,"Expected exception name.")
k.j(B.Z,"Expected 'THEN' after exception condition.")
l=A.a([],s)
for(;;){if(!(!k.n(B.ad)&&!k.n(B.p)&&p[k.b].a!==B.k))break
l.push(k.av())}n.push(new A.ch(m.b,l))}}else n=null
k.j(B.p,"Expected 'END' to close block.")
k.j(B.e,"Expected ';' after 'END'.")
return new A.dL(j,i,o,n)}else return new A.dL(j,i,A.a([],s),null)},
eE(){var s=this,r=s.j(B.d,"Expected variable name."),q=s.bb(),p=s.m(A.a([B.at,B.D],t.B))?s.M():null
s.j(B.e,"Expected ';' after variable declaration.")
return new A.hZ(r.b,q,p)},
bb(){var s,r,q=this,p=t.B
if(q.m(A.a([B.H,B.S,B.I,B.am,B.an,B.ao,B.ap,B.a1,B.a2,B.aq],p)))s=q.a[q.b-1]
else if(q.n(B.d))s=q.q()
else throw A.c(A.q("Unsupported or missing variable type at '"+q.bT().b+"'."))
if(q.m(A.a([B.l],p))){q.M()
while(q.m(A.a([B.n],p)))q.M()
q.j(B.i,"Expected ')' after type modifier.")}r=s.b.toLowerCase()
if(r==="int"||r==="integer"||r==="bigint"||r==="smallint")return B.aw
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
av(){var s,r,q,p,o,n,m,l=this
if(!l.n(B.Q))s=l.n(B.w)&&!l.e1()
else s=!0
if(s)return l.dh()
s=t.B
if(l.m(A.a([B.bl],s))){s=l.j(B.d,"Expected cursor name after OPEN.")
if(l.n(B.e))l.q()
return new A.eQ(s.b)}if(l.m(A.a([B.bm],s))){r=l.j(B.d,"Expected cursor name after FETCH.")
l.j(B.aI,"Expected 'INTO' after cursor name in FETCH.")
q=A.a([],t.s)
do q.push(l.j(B.d,"Expected variable name in FETCH INTO.").b)
while(l.m(A.a([B.n],s)))
if(l.n(B.e))l.q()
return new A.et(r.b,q)}if(l.m(A.a([B.bn],s))){s=l.j(B.d,"Expected cursor name after CLOSE.")
if(l.n(B.e))l.q()
return new A.ed(s.b)}if(l.n(B.R))return l.i3()
if(!l.n(B.X))s=l.n(B.d)&&l.a[l.b].b.toLowerCase()==="for"
else s=!0
if(s)return l.i2()
if(l.n(B.aV))return l.i7()
if(l.n(B.aA)){l.j(B.aA,"Expected 'RETURN'.")
p=l.M()
l.j(B.e,"Expected ';' after return statement.")
return new A.f_(p)}if(l.n(B.d)){o=l.a[l.b].b.toLowerCase()
if(!B.cS.E(0,o)){if(o==="dbms_output"){l.j(B.d,"Expected 'DBMS_OUTPUT'.")
l.j(B.J,"Expected '.' after 'DBMS_OUTPUT'.")
s=l.j(B.d,"Expected 'PUT_LINE'.").b
if(s.toLowerCase()!=="put_line")A.ap(A.q("Expected 'PUT_LINE' call, found '"+s+"'."))
l.j(B.l,"Expected '(' for function call.")
p=l.M()
l.j(B.i,"Expected ')' to close function call.")
l.j(B.e,"Expected ';' after PUT_LINE.")
return new A.ek(p)}if(o==="set"){n=l.aT().b.toLowerCase()
if(!(n==="user"||n==="current_user"||n==="engine_option")){l.q()
return l.eB()}}else return l.eB()}}m=l.eJ()
if(l.n(B.e))l.q()
return m},
i3(){var s,r,q,p,o,n,m,l,k,j=this
j.j(B.R,"Expected 'IF'.")
s=j.M()
j.j(B.Z,"Expected 'THEN' after condition.")
r=t.m
q=A.a([],r)
p=j.a
for(;;){if(!(!j.n(B.ak)&&!j.n(B.a_)&&!j.n(B.p)&&p[j.b].a!==B.k))break
q.push(j.av())}o=A.a([],t.dK)
for(n=t.B;j.m(A.a([B.ak],n));){m=j.M()
j.j(B.Z,"Expected 'THEN' after ELSIF condition.")
l=A.a([],r)
for(;;){if(!(!j.n(B.ak)&&!j.n(B.a_)&&!j.n(B.p)&&p[j.b].a!==B.k))break
l.push(j.av())}o.push(new A.ha(m,l))}if(j.m(A.a([B.a_],n))){k=A.a([],r)
for(;;){if(!(!j.n(B.p)&&p[j.b].a!==B.k))break
k.push(j.av())}}else k=null
j.j(B.p,"Expected 'END' for IF statement.")
j.j(B.R,"Expected 'IF' after 'END'.")
j.j(B.e,"Expected ';' after 'END IF'.")
return new A.ez(s,q,o,k)},
i7(){var s,r,q,p,o=this
o.j(B.aV,"Expected 'WHILE'.")
s=o.M()
r=o.n(B.w)
if(r)o.j(B.w,"Expected 'BEGIN' after WHILE condition.")
else o.j(B.a0,"Expected 'LOOP' or 'BEGIN' after WHILE condition.")
q=A.a([],t.m)
p=o.a
for(;;){if(!(!o.n(B.p)&&p[o.b].a!==B.k))break
q.push(o.av())}o.j(B.p,"Expected 'END' to close block.")
if(r){if(o.n(B.e))o.q()}else{o.j(B.a0,"Expected 'LOOP' after 'END'.")
o.j(B.e,"Expected ';' after 'END LOOP'.")}return new A.fr(s,q)},
i2(){var s,r,q,p,o,n=this
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
o.push(n.av())}n.j(B.p,"Expected 'END' to close FOR loop.")
if(!n.n(B.a0))r=n.n(B.d)&&r[n.b].b.toLowerCase()==="loop"
else r=!0
if(r)n.q()
if(n.n(B.e))n.q()
return new A.ew(s.b,q,p,o)},
eB(){var s,r,q=this,p=q.j(B.d,"Expected variable name.").b
for(s=t.B;q.m(A.a([B.J],s));)p+="."+q.j(B.d,"Expected segment after dot.").b
if(!q.m(A.a([B.at,B.D],s)))throw A.c(A.q("Expected ':=' or '=' for assignment."))
r=q.M()
q.j(B.e,"Expected ';' after assignment.")
return new A.e9(p,r)},
eJ(){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e=this,d="Expected table name to analyze.",c="Expected 'FROM' after 'DELETE'.",b="Expected table name.",a="Expected savepoint name."
e.c=0
s=t.B
if(e.m(A.a([B.bR],s))||e.cb("emit")){if(!e.m(A.a([B.O],s)))e.cb("to")
r=e.j(B.d,"Expected stream name after EMIT TO.")
e.j(B.af,"Expected 'VALUES' after stream name.")
e.j(B.l,"Expected '(' for stream emit values.")
q=A.a([],t.U)
do q.push(e.M())
while(e.m(A.a([B.n],s)))
e.j(B.i,"Expected ')' after stream emit values.")
if(e.n(B.e))e.q()
return new A.eo(r.b,q)}if(e.m(A.a([B.bC],s))){e.m(A.a([B.bD],s))
e.j(B.d,"Expected table name after VACUUM.")
if(e.n(B.e))e.q()
return new A.hY()}if(e.m(A.a([B.aU],s)))if(e.m(A.a([B.N],s))){if(e.m(A.a([B.R],s)))p=e.m(A.a([B.aO],s))
else if(e.n(B.d)&&e.a[e.b].b.toLowerCase()==="if"){e.q()
p=e.n(B.d)&&e.a[e.b].b.toLowerCase()==="exists"
if(p)e.q()}else p=!1
s=e.j(B.d,"Expected table name after 'DROP TABLE'.")
if(e.n(B.e))e.q()
return new A.em(s.b,p)}else if(e.m(A.a([B.aR],s))){s=e.j(B.d,"Expected index name after 'DROP INDEX'.")
if(e.n(B.e))e.q()
return new A.el(s.b)}if(e.m(A.a([B.bJ],s))){o=e.j(B.d,"Expected table name after DESCRIBE.")
if(e.n(B.e))e.q()
return new A.cH(o.b)}if(e.n(B.d)&&e.a[e.b].b.toLowerCase()==="desc"){e.q()
o=e.j(B.d,"Expected table name after DESC.")
if(e.n(B.e))e.q()
return new A.cH(o.b)}if(e.m(A.a([B.bI],s)))if(e.j(B.d,"Expected pragma name.").b.toLowerCase()==="table_info"){e.j(B.l,"Expected '(' after table_info.")
if(e.m(A.a([B.q],s))){n=e.a[e.b-1].b
if(B.a.U(n,"'")||B.a.U(n,'"'))n=B.a.O(n,1,n.length-1)}else n=e.j(B.d,"Expected table name in PRAGMA table_info.").b
e.j(B.i,"Expected ')' after table name in PRAGMA table_info.")
if(e.n(B.e))e.q()
return new A.eS(n)}if(e.m(A.a([B.bK],s))){e.m(A.a([B.N],s))
o=e.j(B.d,"Expected table name after TRUNCATE.")
if(e.n(B.e))e.q()
return new A.fl(o.b)}if(e.m(A.a([B.c5],s)))return e.i_()
if(e.m(A.a([B.bb],s))){e.j(B.v,"Expected 'SELECT' after 'EXPLAIN'.")
return new A.es(e.bn())}if(e.m(A.a([B.P],s))){s=e.a[e.b]
if(s.a!==B.k&&s.b.toLowerCase()==="data")e.q()
if(e.n(B.e))e.q()
return new A.du()}if(e.m(A.a([B.ay],s))){s=e.j(B.d,d)
if(e.n(B.e))e.q()
return new A.dc(s.b)}if(e.m(A.a([B.aB],s)))return e.eC()
if(e.m(A.a([B.P],s))){s=e.a[e.b]
if(s.a!==B.k&&s.b.toLowerCase()==="data")e.q()
if(e.n(B.e))e.q()
return new A.du()}if(e.m(A.a([B.ay],s))){s=e.j(B.d,d)
if(e.n(B.e))e.q()
return new A.dc(s.b)}if(e.m(A.a([B.aB],s)))return e.eC()
if(e.m(A.a([B.bf],s)))return e.i0()
if(e.m(A.a([B.aG],s)))return e.i4()
if(e.m(A.a([B.aP],s)))return e.eF(!0)
if(e.m(A.a([B.A],s)))return e.i1()
if(e.m(A.a([B.v],s)))return e.eI()
if(e.m(A.a([B.Y],s))){e.j(B.B,c)
r=e.j(B.d,b)
m=e.m(A.a([B.G],s))?e.M():null
if(e.n(B.e))e.q()
return new A.dp(r.b,m)}if(e.m(A.a([B.Y],s))){e.j(B.B,c)
r=e.j(B.d,b)
m=e.m(A.a([B.G],s))?e.M():null
if(e.n(B.e))e.q()
return new A.dp(r.b,m)}if(e.n(B.d)&&e.a[e.b].b.toLowerCase()==="update"){e.q()
r=e.j(B.d,b)
if(e.j(B.d,"Expected 'SET' keyword.").b.toLowerCase()!=="set")throw A.c(A.q("Expected 'SET' keyword after table name in UPDATE statement."))
l=e.j(B.d,"Expected column name to update.")
e.j(B.D,"Expected '=' after column name.")
k=e.M()
m=e.m(A.a([B.G],s))?e.M():null
if(e.n(B.e))e.q()
return new A.fo(r.b,l.b,k,m)}if(e.m(A.a([B.w],s))){s=e.a[e.b]
if(s.a!==B.k&&s.b.toLowerCase()==="transaction")e.q()
if(e.n(B.e))e.q()
return new A.ea()}if(e.m(A.a([B.bS],s))){s=e.a[e.b]
if(s.a!==B.k){s=s.b
s=s.toLowerCase()==="transaction"||s.toLowerCase()==="work"}else s=!1
if(s)e.q()
if(e.n(B.e))e.q()
return new A.ee()}if(e.m(A.a([B.bj],s))){j=e.j(B.d,a)
if(e.n(B.e))e.q()
return new A.f6(j.b)}if(e.m(A.a([B.bk],s))){s=e.a[e.b]
if(s.a!==B.k&&s.b.toLowerCase()==="savepoint")e.q()
j=e.j(B.d,a)
if(e.n(B.e))e.q()
return new A.eZ(j.b)}if(e.m(A.a([B.bT],s))){s=e.a
r=s[e.b]
l=r.a!==B.k
if(l&&r.b.toLowerCase()==="to"){e.q()
s=s[e.b]
if(s.a!==B.k&&s.b.toLowerCase()==="savepoint")e.q()
j=e.j(B.d,a)
if(e.n(B.e))e.q()
return new A.f2(j.b)}if(l){s=r.b
s=s.toLowerCase()==="transaction"||s.toLowerCase()==="work"}else s=!1
if(s)e.q()
if(e.n(B.e))e.q()
return new A.f3()}if(e.m(A.a([B.bW],s)))return e.i6()
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
return new A.ey(h,s.b,g)}if(i==="revoke"){e.q()
if(s[e.b].b.toLowerCase()==="all"){e.q()
if(s[e.b].b.toLowerCase()==="privileges")e.q()
h="all"}else h=e.q().b.toLowerCase()
e.j(B.z,"Expected 'ON' after privilege in REVOKE statement.")
s=e.j(B.d,"Expected table name in REVOKE statement.")
e.j(B.B,"Expected 'FROM' in REVOKE statement.")
g=e.n(B.q)?e.j(B.q,"").b:e.j(B.d,"Expected username in REVOKE statement.").b
if(e.n(B.e))e.q()
return new A.f1(h,s.b,g)}if(i==="set"){e.q()
return e.i5()}if(i==="use"){e.q()
f=e.j(B.d,"Expected database name.")
if(e.n(B.e))e.q()
return new A.fp(f.b)}throw A.c(A.q("Unsupported statement beginning with '"+e.bT().b+"'."))},
i5(){var s,r,q,p,o,n,m=this,l=m.a[m.b].b.toLowerCase()
if(l==="user"||l==="current_user"){m.q()
if(m.n(B.D))m.q()
s=m.n(B.q)?m.j(B.q,"").b:m.j(B.d,"Expected username in SET USER statement.").b
if(m.n(B.e))m.q()
return new A.f8(s)}else if(l==="engine_option"){m.q()
r=m.j(B.q,"Expected string literal for option name.")
m.j(B.D,"Expected '=' after option name.")
q=m.q()
p=A.S(q.b.toLowerCase(),"'","")
o=B.a.W(A.S(p,'"',""))
n=o==="on"||o==="true"||o==="1"
if(!n)if(!(o==="off"||o==="false"||o==="0"))throw A.c(A.q("Expected 'ON' or 'OFF' for engine option value."))
if(m.n(B.e))m.q()
return new A.f7(r.b,n)}throw A.c(A.q("Unsupported SET statement: "+m.bT().b))},
i6(){var s,r,q=this,p=t.B
if(q.m(A.a([B.aS],p))){if(q.n(B.e))q.q()
return new A.fc()}else if(q.m(A.a([B.bX],p))){s=q.m(A.a([B.B],p))?q.j(B.d,"Expected table name.").b:null
if(q.n(B.e))q.q()
return new A.fa(s)}else if(q.m(A.a([B.aM],p))){if(!q.m(A.a([B.B],p)))q.m(A.a([B.ah],p))
r=q.j(B.d,"Expected table name after SHOW COLUMNS.")
if(q.n(B.e))q.q()
return new A.f9(r.b)}else{if(!q.m(A.a([B.aN],p)))p=q.n(B.d)&&q.a[q.b].b.toLowerCase()==="databases"
else p=!0
if(p){if(q.n(B.d))q.q()
if(q.n(B.e))q.q()
return new A.fb()}}throw A.c(A.q("Expected 'TABLES', 'INDEXES', 'COLUMNS', or 'SCHEMAS' after 'SHOW'."))},
i0(){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1=this,b2="Expected table name.",b3="Expected '(' to list columns.",b4="Expected ')' to close column list.",b5="Expected '('.",b6="Expected string literal.",b7="Expected ')'.",b8="Expected 'ON' keyword.",b9=t.B
if(b1.m(A.a([B.bo],b9))){s=b1.b
r=b1.j(B.d,"Expected trigger name.")
if(b1.m(A.a([B.bp],b9)))q="BEFORE"
else{if(!b1.m(A.a([B.bq],b9)))throw A.c(A.q("Expected 'BEFORE' or 'AFTER' trigger timing."))
q="AFTER"}if(b1.m(A.a([B.aG],b9)))p="INSERT"
else if(b1.n(B.d)&&b1.a[b1.b].b.toLowerCase()==="update"){b1.q()
p="UPDATE"}else{if(!b1.m(A.a([B.Y],b9)))throw A.c(A.q("Expected 'INSERT', 'UPDATE', or 'DELETE' trigger event."))
p="DELETE"}b1.j(B.z,"Expected 'ON' in trigger declaration.")
o=b1.j(B.d,b2)
n=b1.m(A.a([B.X],b9))
if(n){b1.j(B.br,"Expected 'EACH' after 'FOR'.")
b1.j(B.bs,"Expected 'ROW' after 'FOR EACH'.")}b1.m(A.a([B.y],b9))
m=A.a([],t.a4)
if(b1.m(A.a([B.Q],b9))){b9=b1.a
for(;;){if(!(b1.n(B.d)&&b1.e0()&&b9[b1.b].a!==B.k))break
m.push(b1.eE())}}b1.j(B.w,"Expected 'BEGIN' to start trigger body.")
l=A.a([],t.m)
b9=b1.a
for(;;){if(!(!b1.n(B.p)&&b9[b1.b].a!==B.k))break
l.push(b1.av())}b1.j(B.p,"Expected 'END' to close trigger body.")
if(b1.n(B.e))b1.q()
b9=B.b.bj(b9,s-2,b1.b)
return new A.dl(r.b,q,p,o.b,n,m,l,new A.h(b9,new A.mh(),A.z(b9).i("h<1,e>")).S(0," "))}if(b1.m(A.a([B.bd],b9))){b9=b1.b
r=b1.j(B.d,"Expected procedure name.")
k=b1.eH()
b1.j(B.y,"Expected 'AS' after procedure parameters.")
b1.j(B.w,"Expected 'BEGIN' to start procedure body.")
l=A.a([],t.m)
s=b1.a
for(;;){if(!(!b1.n(B.p)&&s[b1.b].a!==B.k))break
l.push(b1.av())}b1.j(B.p,"Expected 'END' to close procedure body.")
if(b1.n(B.e))b1.q()
b9=B.b.bj(s,b9-2,b1.b)
return new A.cG(r.b,k,l,new A.h(b9,new A.mi(),A.z(b9).i("h<1,e>")).S(0," "))}if(b1.m(A.a([B.az],b9))){b9=b1.b
r=b1.j(B.d,"Expected function name.")
k=b1.eH()
b1.j(B.be,"Expected 'RETURNS' keyword.")
j=b1.bb()
b1.j(B.y,"Expected 'AS' after function return type.")
b1.j(B.w,"Expected 'BEGIN' to start function body.")
l=A.a([],t.m)
s=b1.a
for(;;){if(!(!b1.n(B.p)&&s[b1.b].a!==B.k))break
l.push(b1.av())}b1.j(B.p,"Expected 'END' to close function body.")
if(b1.n(B.e))b1.q()
b9=B.b.bj(s,b9-2,b1.b)
return new A.cF(r.b,k,j,l,new A.h(b9,new A.mj(),A.z(b9).i("h<1,e>")).S(0," "))}if(b1.m(A.a([B.bP],b9))||b1.cb("macro")){s=b1.j(B.d,"Expected macro name.")
k=A.a([],t.s)
if(b1.m(A.a([B.l],b9))){if(!b1.n(B.i))do k.push(b1.j(B.d,"Expected parameter name in macro.").b)
while(b1.m(A.a([B.n],b9)))
b1.j(B.i,"Expected ')' after macro parameters.")}b1.j(B.y,"Expected 'AS' after macro declaration.")
i=b1.M()
if(b1.n(B.e))b1.q()
return new A.cf(s.b,k,i)}if(b1.m(A.a([B.bQ],b9))||b1.cb("stream")){b9=b1.j(B.d,"Expected stream name.")
if(b1.n(B.e))b1.q()
return new A.ej(b9.b)}s=b1.a
if(s[b1.b].b.toLowerCase()==="database"){b1.q()
h=b1.j(B.d,"Expected database name.")
if(b1.n(B.e))b1.q()
return new A.ei(h.b)}if(b1.m(A.a([B.bz],b9))){b1.j(B.N,"Expected 'TABLE' after 'FOREIGN'.")
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
return new A.dg(o.b,g,f.b,e)}else if(b1.m(A.a([B.N],b9))){if(b1.m(A.a([B.R],b9))){d=b1.m(A.a([B.aL],b9))
if(d)b1.m(A.a([B.aO],b9))}else{d=!1
if(b1.n(B.d)&&s[b1.b].b.toLowerCase()==="if"){b1.q()
if(b1.n(B.d)&&s[b1.b].b.toLowerCase()==="not"){b1.q()
d=b1.n(B.d)&&s[b1.b].b.toLowerCase()==="exists"
if(d)b1.q()}}}o=b1.j(B.d,b2)
g=A.a([],t.bd)
if(b1.m(A.a([B.ac],b9))){b1.j(B.ae,"Expected 'OF' after 'PARTITION'.")
s=b1.j(B.d,"Expected parent table name.")
b1.j(B.X,"Expected 'FOR'.")
b1.j(B.af,"Expected 'VALUES'.")
b1.j(B.B,"Expected 'FROM'.")
b1.j(B.l,b5)
c=b1.j(B.q,b6)
b1.j(B.i,b7)
b1.j(B.O,"Expected 'TO'.")
b1.j(B.l,b5)
b=b1.j(B.q,b6)
b1.j(B.i,b7)
a=new A.hE(s.b,c.b,b.b)}else{b1.j(B.l,b3)
do g.push(b1.dg())
while(b1.m(A.a([B.n],b9)))
b1.j(B.i,b4)
a=null}if(a==null&&b1.m(A.a([B.ac],b9))){b1.j(B.T,"Expected 'BY' after 'PARTITION'.")
if(!b1.m(A.a([B.bF],b9)))throw A.c(A.q("Unsupported partitioning strategy."))
b1.j(B.l,b5)
b9=b1.j(B.d,"Expected column name.")
b1.j(B.i,b7)
a0=new A.hD(b9.b)}else a0=null
if(b1.n(B.e))b1.q()
return new A.dk(o.b,g,a0,a,d)}else if(b1.m(A.a([B.aQ],b9))){a1=b1.j(B.d,"Expected relationship name.")
b1.j(B.B,"Expected 'FROM' keyword.")
a2=b1.j(B.d,"Expected source table name.")
b1.j(B.O,"Expected 'TO' keyword.")
a3=b1.j(B.d,"Expected destination table name.")
b1.j(B.z,b8)
a4=b1.j(B.d,"Expected source key column.")
b1.j(B.D,"Expected '='.")
a5=b1.j(B.d,"Expected destination key column.")
if(b1.n(B.e))b1.q()
return new A.dj(a1.b,a2.b,a3.b,a4.b,a5.b)}else if(b1.m(A.a([B.aR],b9))){if(s[b1.b].b.toLowerCase()==="if"){b1.q()
if(s[b1.b].b.toLowerCase()==="not")b1.q()
if(s[b1.b].b.toLowerCase()==="exists")b1.q()}a6=b1.j(B.d,"Expected index name.")
b1.j(B.z,b8)
o=b1.j(B.d,b2)
b1.j(B.l,"Expected '(' before column names.")
a7=A.a([],t.s)
do a7.push(A.R(b1.M()))
while(b1.m(A.a([B.n],b9)))
b1.j(B.i,"Expected ')' after column names.")
a8=B.b.S(a7,",")
if(b1.m(A.a([B.b_],b9))){a9=s[b1.b].b.toLowerCase()
b1.q()}else a9=null
if(b1.n(B.e))b1.q()
return new A.dh(a6.b,o.b,a8,a9)}else if(b1.m(A.a([B.cn],b9))){b9=b1.j(B.d,"Expected policy name.")
b1.j(B.z,b8)
s=b1.j(B.d,b2)
b1.j(B.b_,"Expected 'USING' keyword.")
b1.j(B.l,"Expected '(' before policy condition.")
b0=b1.M()
b1.j(B.i,"Expected ')' after policy condition.")
if(b1.n(B.e))b1.q()
return new A.di(b9.b,s.b,b0)}throw A.c(A.q("Expected 'TABLE', 'RELATIONSHIP', 'INDEX', or 'POLICY' after 'CREATE'."))},
dg(){var s,r,q,p,o,n,m,l,k,j,i,h=this,g=null,f=h.j(B.d,"Expected column name."),e=h.bb()
for(s=t.B,r=h.a,q=g,p=q,o=p,n=o,m=n,l=!1,k=!1,j=!1;;)if(h.m(A.a([B.c0],s))){h.j(B.c1,"Expected 'KEY' after 'PRIMARY'.")
l=!0}else if(h.m(A.a([B.aL],s))){if(!h.m(A.a([B.ag],s)))i=h.n(B.d)&&r[h.b].b.toLowerCase()==="null"
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
h.j(B.az,"Expected 'FUNCTION' in MASKED WITH clause.")
h.j(B.D,"Expected '=' after 'FUNCTION'.")
q=h.j(B.q,"Expected function name string.").b
h.j(B.i,"Expected ')' after MASKED WITH clause.")}else break
return new A.aZ(f.b,e,l,k,m,n,j,o,p,q)},
i_(){var s,r,q,p,o,n,m=this,l=null
m.j(B.N,"Expected 'TABLE' after 'ALTER'.")
s=m.j(B.d,"Expected table name.").b
r=t.B
if(m.m(A.a([B.c6],r))){q=m.dg()
if(m.n(B.e))m.q()
return new A.bR(s,B.b2,q,l,l,l,l,l)}else if(m.m(A.a([B.aU],r))){m.j(B.aj,"Expected 'COLUMN' after 'DROP'.")
p=m.j(B.d,"Expected column name to drop.")
if(m.n(B.e))m.q()
return new A.bR(s,B.b3,l,p.b,l,l,l,l)}else{r=m.a
o=r[m.b].b
if(o.toLowerCase()==="rename"){m.q()
if(m.n(B.aj))m.q()
r=m.j(B.d,"Expected old column name.")
m.j(B.O,"Expected 'TO' after old column name.")
o=m.j(B.d,"Expected new column name.")
if(m.n(B.e))m.q()
return new A.bR(s,B.b4,l,l,r.b,o.b,l,l)}else if(o.toLowerCase()==="alter"){m.q()
if(m.n(B.aj))m.q()
o=m.j(B.d,"Expected target column name.")
if(r[m.b].b.toLowerCase()==="type")m.q()
n=m.bb()
if(m.n(B.e))m.q()
return new A.bR(s,B.b5,l,l,l,l,o.b,n)}else throw A.c(A.q("Expected 'ADD', 'DROP', 'RENAME', or 'ALTER' in ALTER TABLE statement."))}},
eF(a){var s,r,q,p,o,n,m,l,k,j,i,h=this,g=null
h.j(B.aI,"Expected 'INTO' keyword.")
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
if(h.m(A.a([B.z],r))){h.j(B.bL,"Expected 'CONFLICT' after ON.")
if(h.m(A.a([B.l],r))){l=h.j(B.d,"Expected conflict target column name.").b
h.j(B.i,"Expected ')' after conflict target column.")}h.j(B.bM,"Expected 'DO' after ON CONFLICT.")
j=h.m(A.a([B.bN],r))
if(!j)if(h.n(B.d)&&h.a[h.b].b.toLowerCase()==="update"){h.q()
h.j(B.cT,"Expected 'SET' after DO UPDATE.")
k=A.o(t.N,t.k)
do{i=h.j(B.d,"Expected column name in SET clause.")
h.j(B.at,"Expected '=' in SET clause.")
k.k(0,i.b,h.M())}while(h.m(A.a([B.n],r)))}}else j=!1
if(h.n(B.e))h.q()
r=p.length>1?p:g
return new A.cL(s.b,m,r,q,a,j,l,k)},
i4(){return this.eF(!1)},
bn(){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2,b3,b4,b5=this,b6=null,b7="Expected table alias.",b8=t.B
if(b5.m(A.a([B.bh],b8)))s=!0
else{s=b5.n(B.d)&&b5.a[b5.b].b.toLowerCase()==="distinct"
if(s)b5.q()}r=A.a([],t.u)
if(b5.m(A.a([B.as],b8)))r.push(new A.ai(new A.I(A.a(["*"],t.s)),b6))
else do{q=b5.M()
if(b5.m(A.a([B.y],b8)))p=b5.j(B.d,"Expected alias identifier.").b
else p=b5.n(B.d)?b5.q().b:b6
r.push(new A.ai(q,p))}while(b5.m(A.a([B.n],b8)))
o=""
n=b6
m=b6
if(b5.m(A.a([B.B],b8))){if(b5.n(B.l))l=b5.aT().a===B.v||b5.aT().a===B.A
else l=!1
if(l){b5.j(B.l,"Expected '(' before FROM subquery.")
k=b5.av()
b5.j(B.i,"Expected ')' after FROM subquery.")
if(!(k instanceof A.aS))throw A.c(A.q("Expected SelectStmt inside FROM subquery."))
n=k}else if((b5.n(B.d)||b5.n(B.P))&&b5.aT().a===B.l){j=b5.q().b
b5.j(B.l,"Expected '(' after function name.")
i=A.a([],t.U)
if(!b5.n(B.i))do i.push(b5.M())
while(b5.m(A.a([B.n],b8)))
b5.j(B.i,"Expected ')' after function arguments.")
m=new A.af(j,i)
o=j}else{h=A.a([],t.s)
l=b5.a
do if(b5.m(A.a([B.d,B.aS,B.aM,B.aN,B.aJ,B.P],b8)))h.push(l[b5.b-1].b)
else if(b5.n(B.d))h.push(b5.q().b)
else throw A.c(A.q("Expected source table name."))
while(b5.m(A.a([B.J],b8)))
o=B.b.S(h,".")}}if(b5.n(B.y)&&b5.aT().a!==B.ae){b5.q()
g=b5.j(B.d,b7).b}else{l=b5.a
f=l[b5.b]
if(f.a===B.d){f=f.b
l=f.toLowerCase()!=="left"&&f.toLowerCase()!=="right"&&f.toLowerCase()!=="full"&&f.toLowerCase()!=="outer"&&!B.b.E(A.a([B.C,B.G,B.ai,B.a4,B.al,B.A,B.e,B.k],b8),l[b5.b].a)}else l=!1
g=l?b5.q().b:b6}if(b5.m(A.a([B.y],b8))){b5.j(B.ae,"Expected 'OF' after 'AS'.")
if(b5.m(A.a([B.aJ],b8))){b5.j(B.aK,"Expected TIME after SYSTEM in AS OF SYSTEM TIME.")
e=new A.e7(b5.M())}else if(b5.m(A.a([B.bE],b8)))e=new A.e7(b5.M())
else throw A.c(A.q("Expected SYSTEM TIME or TRANSACTION after AS OF."))}else e=b6
if(n!=null&&o.length===0)o=g==null?"subquery":g
d=A.a([],t.R)
for(l=b5.a;;){c=!1
b=!1
a=!1
a0=!0
if(b5.n(B.d)&&l[b5.b].b.toLowerCase()==="inner"){f=b5.b
if(l[f].a!==B.k)b5.b=f+1
b5.j(B.C,"Expected 'JOIN' after 'INNER'.")
a1=!1}else{a1=b5.n(B.d)&&l[b5.b].b.toLowerCase()==="cross"
if(a1){f=b5.b
if(l[f].a!==B.k)b5.b=f+1
b5.j(B.C,"Expected 'JOIN' after 'CROSS'.")}else{c=b5.n(B.d)&&l[b5.b].b.toLowerCase()==="left"
if(c){f=b5.b
if(l[f].a!==B.k)b5.b=f+1
if(b5.n(B.d)&&l[b5.b].b.toLowerCase()==="outer"){f=b5.b
if(l[f].a!==B.k)b5.b=f+1}b5.j(B.C,"Expected 'JOIN' after 'LEFT [OUTER]'.")}else{b=b5.n(B.d)&&l[b5.b].b.toLowerCase()==="right"
if(b){f=b5.b
if(l[f].a!==B.k)b5.b=f+1
if(b5.n(B.d)&&l[b5.b].b.toLowerCase()==="outer"){f=b5.b
if(l[f].a!==B.k)b5.b=f+1}b5.j(B.C,"Expected 'JOIN' after 'RIGHT [OUTER]'.")}else{a=b5.n(B.d)&&l[b5.b].b.toLowerCase()==="full"
if(a){f=b5.b
if(l[f].a!==B.k)b5.b=f+1
if(b5.n(B.d)&&l[b5.b].b.toLowerCase()==="outer"){f=b5.b
if(l[f].a!==B.k)b5.b=f+1}b5.j(B.C,"Expected 'JOIN' after 'FULL [OUTER]'.")}else a0=b5.m(A.a([B.C],b8))}}}}if(!a0)break
if(b5.n(B.l))f=b5.aT().a===B.v||b5.aT().a===B.A
else f=!1
if(f){b5.j(B.l,"Expected '(' before JOIN subquery.")
k=b5.av()
b5.j(B.i,"Expected ')' after JOIN subquery.")
if(!(k instanceof A.aS))throw A.c(A.q("Expected SelectStmt inside JOIN subquery."))
a2=k
a3=""}else{a3=b5.j(B.d,"Expected table to join.").b
a2=b6}if(b5.m(A.a([B.y],b8)))a4=b5.j(B.d,b7).b
else{f=l[b5.b]
if(f.a===B.d){f=f.b
f=f.toLowerCase()!=="left"&&f.toLowerCase()!=="right"&&f.toLowerCase()!=="full"&&f.toLowerCase()!=="outer"&&f.toLowerCase()!=="inner"&&f.toLowerCase()!=="cross"&&!B.b.E(A.a([B.z,B.C,B.G,B.ai,B.a4,B.al,B.A,B.e,B.k],b8),l[b5.b].a)}else f=!1
if(f){f=b5.b
a4=l[(l[f].a!==B.k?b5.b=f+1:f)-1].b}else a4=b6}if(a2!=null&&a3.length===0)a3=a4==null?"join_subquery":a4
if(a1&&!b5.m(A.a([B.z],b8)))a5=new A.ag(1)
else{b5.j(B.z,"Expected 'ON' condition for JOIN.")
a5=b5.M()}d.push(new A.bp(a3,a2,a4,a5,c,b,a))}a6=b5.m(A.a([B.G],b8))?b5.M():b6
if(b5.m(A.a([B.ai],b8))){b5.j(B.T,"Expected 'BY' after 'GROUP'.")
if(b5.m(A.a([B.bv],b8))){b5.j(B.l,"Expected '(' after ROLLUP.")
i=A.a([],t.U)
do i.push(b5.M())
while(b5.m(A.a([B.n],b8)))
b5.j(B.i,"Expected ')' after ROLLUP.")
a7=new A.dR(i)}else if(b5.m(A.a([B.bw],b8))){b5.j(B.l,"Expected '(' after CUBE.")
i=A.a([],t.U)
do i.push(b5.M())
while(b5.m(A.a([B.n],b8)))
b5.j(B.i,"Expected ')' after CUBE.")
a7=new A.dn(i)}else{f=t.U
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
a7=new A.cJ(a8)}else{i=A.a([],f)
do i.push(b5.M())
while(b5.m(A.a([B.n],b8)))
a7=i.length===1?i[0]:new A.cJ(A.a([i],t.h))}}}else a7=b6
a9=b5.m(A.a([B.c_],b8))?b5.M():b6
if(b5.m(A.a([B.a4],b8))){b5.j(B.T,"Expected 'BY' after 'ORDER'.")
q=b5.M()
if(b5.m(A.a([B.aX],b8)))b0=!0
else{f=b5.m(A.a([B.ax],b8))
b0=!f}b1=new A.dH(q,b0)}else b1=b6
b2=b6
if(b5.m(A.a([B.al],b8))){b3=A.a3(b5.j(B.a3,"Expected numeric limit.").b,b6)
if(!b5.m(A.a([B.bi],b8)))f=b5.n(B.d)&&l[b5.b].b.toLowerCase()==="offset"
else f=!0
if(f){if(l[b5.b].b.toLowerCase()==="offset")b5.q()
b2=A.a3(b5.j(B.a3,"Expected numeric offset.").b,b6)}}else b3=b6
if(b5.m(A.a([B.A],b8))){b5.j(B.aQ,"Expected 'RELATIONSHIP' after 'WITH'.")
b4=b5.j(B.d,"Expected relationship name.").b}else b4=b6
if(b5.n(B.e))b5.q()
return A.p2(e,m,n,a7,a9,s,b6,d,b3,b2,b1,r,g,o,a6,b4)},
M(){var s,r,q=this,p=q.eA()
for(s=t.B,r=q.a;q.m(A.a([B.bZ],s));)p=new A.a0(r[q.b-1].b,p,q.eA())
return p},
eA(){var s,r,q=this,p=q.eD()
for(s=t.B,r=q.a;q.m(A.a([B.aT],s));)p=new A.a0(r[q.b-1].b,p,q.eD())
return p},
eD(){var s,r,q,p,o,n=this,m=n.cc(),l=t.B
if(n.m(A.a([B.bY],l))){s=n.cc()
n.j(B.aT,"Expected 'AND' after BETWEEN lower bound.")
return new A.a0("AND",new A.a0(">=",m,s),new A.a0("<=",m,n.cc()))}if(n.m(A.a([B.ah],l))){n.j(B.l,"Expected '(' after IN")
if(n.n(B.v)||n.n(B.A)){r=n.av()
n.j(B.i,"Expected ')' after subquery.")
if(r instanceof A.aS)q=new A.cs(r)
else throw A.c(A.q("Expected SelectStmt inside subquery."))}else{p=A.a([],t.U)
do p.push(n.M())
while(n.m(A.a([B.n],l)))
n.j(B.i,"Expected ')' after IN list.")
q=new A.af("in_list",p)}return new A.a0("IN",m,q)}for(o=n.a;n.m(A.a([B.D,B.aW,B.cd,B.cf,B.ce,B.cg,B.bU,B.bV,B.bO],l));)m=new A.a0(o[n.b-1].b,m,n.cc())
return m},
cc(){var s,r,q=this,p=q.eG()
for(s=t.B,r=q.a;q.m(A.a([B.cb,B.ar,B.ch],s));)p=new A.a0(r[q.b-1].b,p,q.eG())
return p},
eG(){var s,r,q=this,p=q.di()
for(s=t.B,r=q.a;q.m(A.a([B.as,B.cc,B.ci],s));)p=new A.a0(r[q.b-1].b,p,q.di())
return p},
di(){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4=this,a5="Expected '(' after CAST.",a6="Expected 'AS' inside CAST.",a7="Expected ')' to close CAST.",a8=t.B
if(a4.m(A.a([B.aZ],a8))){s=a4.a[a4.b-1].b
if(s==="?")r=new A.aQ(s,a4.c++)
else if(B.a.U(s,"$"))r=new A.aQ(s,A.d8(B.a.az(s,1))-1)
else throw A.c(A.q("Unknown placeholder format: "+s))}else if(a4.m(A.a([B.ar],a8))){q=a4.di()
r=q instanceof A.ag&&typeof q.b=="number"?new A.ag(-A.ir(q.b)):new A.a0("-",new A.ag(0),q)}else if(a4.m(A.a([B.c9],a8)))r=new A.ag(!0)
else if(a4.m(A.a([B.ca],a8)))r=new A.ag(!1)
else if(a4.m(A.a([B.ag],a8)))r=new A.ag(null)
else if(a4.m(A.a([B.a3],a8)))r=new A.ag(A.wf(a4.a[a4.b-1].b))
else if(a4.m(A.a([B.q],a8))){s=a4.a[a4.b-1].b
p=s.length
if(p>=2)if(!(B.a.U(s,"'")&&B.a.B(s,"'")))o=B.a.U(s,'"')&&B.a.B(s,'"')
else o=!0
else o=!1
r=new A.ag(o?B.a.O(s,1,p-1):s)}else if(a4.m(A.a([B.cm],a8))){n=A.a([],t.n)
if(!a4.n(B.aY))do{m=a4.m(A.a([B.ar],a8))?-1:1
n.push(m*A.cA(a4.j(B.a3,"Expected vector element double.").b))}while(a4.m(A.a([B.n],a8)))
a4.j(B.aY,"Expected ']' to close vector literal.")
r=new A.cv(n)}else if(a4.m(A.a([B.bH],a8))){a4.j(B.l,a5)
l=a4.M()
a4.j(B.y,a6)
k=a4.bb()
a4.j(B.i,a7)
r=new A.ce(l,k)}else if(a4.m(A.a([B.d,B.bt,B.aK,B.P,B.H,B.S,B.I,B.am,B.an,B.ao,B.ap,B.a1,B.a2,B.aq,B.aP],a8))){p=a4.a
j=p[a4.b-1].b
if(j.toLowerCase()==="match"||j.toLowerCase()==="contains"){a4.j(B.l,"Expected '(' after MATCH.")
i=a4.M()
a4.j(B.n,"Expected ',' after column name in MATCH.")
h=a4.M()
a4.j(B.i,"Expected ')' after search query in MATCH.")
g=A.R(i)
r=new A.eI(g,h instanceof A.ag?J.x(h.b):A.R(h))}else if(j.toLowerCase()==="case"){f=A.a([],t.eV)
for(;;){if(!a4.n(B.ad))o=a4.n(B.d)&&p[a4.b].b.toLowerCase()==="when"
else o=!0
if(!o)break
o=a4.b
if(p[o].a!==B.k)a4.b=o+1
e=a4.M()
a4.j(B.Z,"Expected 'THEN' after WHEN condition.")
f.push(new A.dX(e,a4.M()))}if(a4.m(A.a([B.a_],a8)))d=a4.M()
else if(a4.n(B.d)&&p[a4.b].b.toLowerCase()==="else"){a4.q()
d=a4.M()}else d=null
a4.j(B.p,"Expected 'END' to close CASE expression.")
r=new A.dd(f,d)}else if(j.toLowerCase()==="cast"){a4.j(B.l,a5)
l=a4.M()
a4.j(B.y,a6)
k=a4.bb()
a4.j(B.i,a7)
r=new A.ce(l,k)}else if(a4.n(B.l)){a4.q()
p=t.U
c=A.a([],p)
if(a4.n(B.as)){a4.q()
c.push(new A.I(A.a(["*"],t.s)))}else if(!a4.n(B.i))do c.push(a4.M())
while(a4.m(A.a([B.n],a8)))
a4.j(B.i,"Expected ')' after function arguments.")
if(a4.m(A.a([B.bg],a8))){a4.j(B.l,"Expected '(' after OVER.")
b=A.a([],p)
if(a4.m(A.a([B.ac],a8))){a4.j(B.T,"Expected 'BY' after PARTITION.")
do b.push(a4.M())
while(a4.m(A.a([B.n],a8)))}if(a4.m(A.a([B.a4],a8))){a4.j(B.T,"Expected 'BY' after ORDER.")
a=a4.M()
if(a4.m(A.a([B.aX],a8)))a0=!0
else{p=a4.m(A.a([B.ax],a8))
a0=!p}a1=new A.dH(a,a0)}else a1=null
a4.j(B.i,"Expected ')' to close OVER clause.")
r=new A.bM(j,c,b,a1)}else r=new A.af(j,c)}else{a2=A.a([j],t.s)
while(a4.m(A.a([B.J],a8)))a2.push(a4.j(B.d,"Expected identifier after dot.").b)
r=new A.I(a2)}}else{if(a4.n(B.l))p=a4.aT().a===B.v||a4.aT().a===B.A
else p=!1
if(p){a4.j(B.l,"Expected '(' before subquery.")
a3=a4.av()
a4.j(B.i,"Expected ')' after subquery.")
if(a3 instanceof A.aS)r=new A.cs(a3)
else throw A.c(A.q("Expected SelectStmt inside subquery."))}else{if(a4.m(A.a([B.l],a8))){l=a4.M()
a4.j(B.i,"Expected ')' after expression.")}else throw A.c(A.q("Unexpected token '"+a4.bT().b+"' in expression."))
r=l}}for(p=a4.a;;)if(a4.n(B.cj)){o=a4.b
if(p[o].a!==B.k)a4.b=o+1
r=new A.b9(r,a4.j(B.q,"Expected string literal path after JSON operator '->'.").b,!1)}else if(a4.n(B.ck)){o=a4.b
if(p[o].a!==B.k)a4.b=o+1
r=new A.b9(r,a4.j(B.q,"Expected string literal path after JSON operator '->>'.").b,!0)}else if(a4.m(A.a([B.cl],a8)))r=new A.ce(r,a4.bb())
else break
return r},
eH(){var s,r=this,q=A.a([],t.gg),p=t.B
if(r.m(A.a([B.l],p))){if(!r.n(B.i))do{s=r.j(B.d,"Expected parameter name.")
r.bb()
q.push(new A.hC(s.b))}while(r.m(A.a([B.n],p)))
r.j(B.i,"Expected ')' after parameter list.")}return q},
eC(){var s,r,q=this,p=q.j(B.d,"Expected procedure name in CALL statement.")
q.j(B.l,"Expected '(' for CALL argument list.")
s=A.a([],t.U)
if(!q.n(B.i)){r=t.B
do s.push(q.M())
while(q.m(A.a([B.n],r)))}q.j(B.i,"Expected ')' after CALL argument list.")
if(q.n(B.e))q.q()
return new A.ec(p.b,s)},
i1(){var s,r,q,p=this,o=t.B,n=p.m(A.a([B.bu],o)),m=A.o(t.N,t.z)
do{s=p.j(B.d,"Expected CTE name.")
if(p.m(A.a([B.l],o))){do p.j(B.d,"Expected column name in CTE parameter list.")
while(p.m(A.a([B.n],o)))
p.j(B.i,"Expected ')' after CTE column names.")}p.j(B.y,"Expected 'AS' after CTE name.")
p.j(B.l,"Expected '(' before CTE query.")
p.j(B.v,"Expected 'SELECT' inside CTE query.")
r=p.eI()
p.j(B.i,"Expected ')' after CTE query.")
m.k(0,s.b.toLowerCase(),r)}while(p.m(A.a([B.n],o)))
p.j(B.v,"Expected 'SELECT' after CTE definition.")
q=p.bn()
return new A.dm(m,q,n,q.a,q.b,q.c,q.d,q.e,q.f,q.r,q.w,q.x,q.y,q.z,q.Q,q.as,q.at,q.ax)},
eI(){var s,r,q,p=this,o=p.bn(),n=p.a[p.b].a
if(n===B.aC){s=A.a([o],t.I)
r=A.a([],t.f7)
for(n=t.B;p.m(A.a([B.aC],n));){q=p.m(A.a([B.bc],n))
p.j(B.v,"Expected 'SELECT' after 'UNION'.")
s.push(p.bn())
r.push(q)}return new A.cW(s,r)}if(n===B.aD){s=A.a([o],t.I)
for(n=t.B;p.m(A.a([B.aD],n));){p.j(B.v,"Expected 'SELECT' after 'INTERSECT'.")
s.push(p.bn())}return new A.dy(s)}if(n===B.aE){s=A.a([o],t.I)
for(n=t.B;p.m(A.a([B.aE],n));){p.j(B.v,"Expected 'SELECT' after 'EXCEPT'.")
s.push(p.bn())}return new A.dr(s)}return o}}
A.mh.prototype={
$1(a){if(a.a===B.q)return"'"+A.S(a.b,"'","''")+"'"
return a.b},
$S:30}
A.mi.prototype={
$1(a){if(a.a===B.q)return"'"+A.S(a.b,"'","''")+"'"
return a.b},
$S:30}
A.mj.prototype={
$1(a){if(a.a===B.q)return"'"+A.S(a.b,"'","''")+"'"
return a.b},
$S:30}
A.f.prototype={
c9(){return"TokenType."+this.b}}
A.N.prototype={
l(a){var s=this
return"Token("+s.a.l(0)+', "'+s.b+'", L:'+s.c+":"+s.d+")"}}
A.iA.prototype={
j_(a,b){return}}
A.aY.prototype={
l(a){return"Ptr("+this.a+", "+this.b+")"}}
A.h0.prototype={
iT(a){var s,r,q,p,o,n,m=this
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
ap(){var s,r,q,p=this,o=p.a,n=p.b
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
p.e=p.hK()}},
hK(){var s,r,q,p,o,n,m=this,l=m.d
for(s=m.a,r=m.b;l!==-1;l=n){q=s.C(r,l).c
q===$&&A.b()
if(q.getUint8(1)===1){s.u(r,l,!1)
return l}p=q.getUint16(2,!1)
if(p===0){s.u(r,l,!1)
return l}o=m.Q
o===$&&A.b()
n=q.getInt32(o+p*4,!1)
s.u(r,l,!1)}return 0},
dn(a){var s,r,q,p,o=this
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
aA(a,b){var s,r,q,p,o,n=t.o
n.a(a)
n.a(b)
if(this.c===1)return B.h.A(a[0],b[0])
s=a.length
r=b.length
q=s<r?s:r
for(p=0;p<q;++p){o=B.h.A(a[p],b[p])
if(o!==0)return o}return B.c.A(s,r)},
bi(a1){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a=this,a0=a.c===1
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
l=a.aR(n,s.b(a1)?a1:A.a([r],t.n),m)
if(l<m&&o.getFloat64(4+l*8,!1)===r){a0=a.Q
a0===$&&A.b()
k=o.getInt32(a0+l*4,!1)
a0=a.as
a0===$&&A.b()
j=o.getUint16(a0+l*2,!1)
a0=a.r
a0.toString
q.u(p,a0,!1)
return new A.aY(k,j)}s=a.r
s.toString
q.u(p,s,!1)}}i=a.d
for(s=a.a,q=a.b;;i=b){n=s.C(q,i)
p=n.c
p===$&&A.b()
o=p.getUint8(1)
m=p.getUint16(2,!1)
if(o===1){l=a.aR(n,a1,m)
if(l<m)if(a0){r=t.o.a(a1)[0]
h=p.getFloat64(4+l*8,!1)===r}else h=a.aA(a.ao(n,l),a1)===0
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
return new A.aY(k,j)}o=a.at
o===$&&A.b()
g=p.getInt32(o,!1)
s.u(q,i,!1)
if(g!==-1){f=s.C(q,g)
p=f.c
p===$&&A.b()
e=p.getUint16(2,!1)
d=a.aR(f,a1,e)
if(d<e)if(a0){r=t.o.a(a1)[0]
c=p.getFloat64(4+d*8,!1)===r}else c=a.aA(a.ao(f,d),a1)===0
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
return new A.aY(k,j)}s.u(q,g,!1)}return null}else{l=a.aR(n,a1,m)
o=a.Q
o===$&&A.b()
b=p.getInt32(o+l*4,!1)
s.u(q,i,!1)}}},
fk(a){var s,r,q,p,o,n,m,l=this,k=l.d
for(s=l.a,r=l.b;;k=m){q=s.C(r,k)
p=q.c
p===$&&A.b()
if(p.getUint8(1)===1){s.u(r,k,!1)
return k}o=l.aR(q,a,p.getUint16(2,!1))
n=l.Q
n===$&&A.b()
m=p.getInt32(n+o*4,!1)
s.u(r,k,!1)}},
cQ(a,a0){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c=this,b=A.a([],t.cK)
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
s=m}}else r=c.fk(a)
for(q=c.a,p=c.b,o=a0!=null,n=c.c===1;r!==-1;r=d){l=q.C(p,r)
k=l.c
k===$&&A.b()
j=k.getUint16(2,!1)
for(i=0;i<j;++i){if(n){h=k.getFloat64(4+i*8,!1)
if(a!=null&&h<a[0])continue
if(o&&h>a0[0]){q.u(p,r,!1)
return b}}else{g=c.ao(l,i)
if(a!=null&&c.aA(g,a)<0)continue
if(o&&c.aA(g,a0)>0){q.u(p,r,!1)
return b}}f=c.Q
f===$&&A.b()
e=k.getInt32(f+i*4,!1)
f=c.as
f===$&&A.b()
b.push(new A.aY(e,k.getUint16(f+i*2,!1)))}f=c.at
f===$&&A.b()
d=k.getInt32(f,!1)
q.u(p,r,!1)}return b},
hN(a,b){var s,r,q,p=this.z
p===$&&A.b()
s=4+b*p
r=A.a([],t.n)
for(p=this.c,q=0;q<p;++q)r.push(a.getFloat64(s+q*8,!1))
return r},
iz(a6,a7){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4=this,a5=$.cN
if(a5!=null){s=B.b.gV(B.b.gV(a4.b.split("/")).split("\\"))
r=A.S(s,".idx","")
if(B.a.U(r,"idx_")){q=r.split("_")
p=q.length>=2?q[1]:r}else p=r
s=a5.a.b
s===$&&A.b()
s=s.aX(p).a
if(s>0)return s}if(a6==null){o=a4.d
s=a4.a
m=a4.b
for(;;){if(!!0){n=0
break}l=s.C(m,o).c
l===$&&A.b()
if(l.getUint8(1)===1){s.u(m,o,!1)
n=o
break}k=a4.Q
k===$&&A.b()
j=l.getInt32(k,!1)
s.u(m,o,!1)
o=j}}else n=a4.fk(a6)
s=a4.a
m=a4.b
i=s.a_(m)
h=new Uint8Array(4096)
g=A.aq(h,0,null)
for(l=a4.c===1,s=s.d,f=0;n!==-1;){e=s.h(0,new A.ao(m,n))
if(e!=null){k=e.c
k===$&&A.b()
d=k}else{i.cF(n,h)
d=g}c=d.getUint16(2,!1)
k=c>0
if(k&&a6==null&&a7==null){f+=c
k=a4.at
k===$&&A.b()
n=d.getInt32(k,!1)
continue}if(k&&l&&a6!=null&&a7!=null&&a6[0]===a7[0]){b=a6[0]
a=d.getFloat64(4,!1)
a0=d.getFloat64(4+(c-1)*8,!1)
if(a===b&&a0===b){f+=c
k=a4.at
k===$&&A.b()
n=d.getInt32(k,!1)
continue}}for(k=a7!=null,a1=0;a1<c;++a1){if(l){a2=d.getFloat64(4+a1*8,!1)
if(a6!=null&&a2<a6[0])continue
if(k&&a2>a7[0])return f}else{a3=a4.hN(d,a1)
if(a6!=null&&a4.aA(a3,a6)<0)continue
if(k&&a4.aA(a3,a7)>0)return f}++f}k=a4.at
k===$&&A.b()
n=d.getInt32(k,!1)}return f},
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
if(s)if(a2.aA(a3,a2.ao(p,o-1))>0){a2.b9(p,a3,a4,a5)
r.u(q,a2.e,!0)
return!0}r.u(q,a2.e,!1)}a2.f=!1
s=a2.a
r=a2.b
n=s.C(r,a2.d)
q=n.c
q===$&&A.b()
if(q.getUint8(1)===1){o=q.getUint16(2,!1)
m=a2.aR(n,a3,o)
if(m<o&&a2.aA(a2.ao(n,m),a3)===0)a2.f=!0
if(!a2.b9(n,a3,a4,a5)){l=s.a_(r).a4()
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
a2.b0(k,e,d)
j.$flags&2&&A.i(j,8)
j.setInt32(i+e*4,c,!1)
j.$flags&2&&A.i(j,10)
j.setUint16(h+e*2,b,!1);++e}j.$flags&2&&A.i(j,10)
j.setUint16(2,e,!1)
q.$flags&2&&A.i(q,10)
q.setUint16(2,g,!1)
a=a2.ao(k,0)
if(a2.aA(a3,a)>=0)a2.b9(k,a3,a4,a5)
else a2.b9(n,a3,a4,a5)
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
a2.b0(a1,0,a)
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
a2.dn(a0)
a2.e=l}else s.u(r,a2.d,!0)}else{s.u(r,a2.d,!1)
a2.eu(a2.d,a3,a4,a5)}return!a2.f},
eu(b1,b2,b3,b4){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5=this,a6=null,a7=a5.a,a8=a5.b,a9=a7.C(a8,b1),b0=a9.c
b0===$&&A.b()
s=b0.getUint8(1)
r=b0.getUint16(2,!1)
if(s===1){q=a5.aR(a9,b2,r)
if(q<r&&a5.aA(a5.ao(a9,q),b2)===0)a5.f=!0
if(a5.b9(a9,b2,b3,b4)){a7.u(a8,b1,!0)
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
a5.b0(o,j,i)
s.$flags&2&&A.i(s,8)
s.setInt32(n+j*4,h,!1)
s.$flags&2&&A.i(s,10)
s.setUint16(m+j*2,g,!1);++j}s.$flags&2&&A.i(s,10)
s.setUint16(2,j,!1)
b0.$flags&2&&A.i(b0,10)
b0.setUint16(2,l,!1)
f=a5.ao(o,0)
if(a5.aA(b2,f)>=0)a5.b9(o,b2,b3,b4)
else a5.b9(a9,b2,b3,b4)
a7.u(a8,b1,!0)
a7.u(a8,p,!0)
a5.e=p
return new A.h2(f,p)}else{q=a5.aR(a9,b2,r)
s=a5.Q
s===$&&A.b()
e=b0.getInt32(s+q*4,!1)
a7.u(a8,b1,!1)
d=a5.eu(e,b2,b3,b4)
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
a5.b0(o,j,i);++j
m.$flags&2&&A.i(m,8)
m.setInt32(s+j*4,a2,!1)}m.$flags&2&&A.i(m,10)
m.setUint16(2,j,!1)
b.$flags&2&&A.i(b,10)
b.setUint16(2,l,!1)
if(a5.aA(b0,a0)>=0)a5.d6(o,b0,n)
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
a5.b0(a4,0,a0)
b0.$flags&2&&A.i(b0,8)
b0.setInt32(s,b1,!1)
b0.$flags&2&&A.i(b0,8)
b0.setInt32(s+4,p,!1)
a7.u(a8,a3,!0)
a5.dn(a3)
return a6}return new A.h2(a0,p)}},
b9(a,b,c,d){var s,r,q,p,o,n,m=this,l=a.c
l===$&&A.b()
s=l.getUint16(2,!1)
r=m.y
r===$&&A.b()
if(s>=r)return!1
q=m.aR(a,b,s)
for(p=s;p>q;p=o){o=p-1
m.b0(a,p,m.ao(a,o))
r=m.Q
r===$&&A.b()
n=l.getInt32(r+o*4,!1)
l.$flags&2&&A.i(l,8)
l.setInt32(r+p*4,n,!1)
n=m.as
n===$&&A.b()
r=l.getUint16(n+o*2,!1)
l.$flags&2&&A.i(l,10)
l.setUint16(n+p*2,r,!1)}m.b0(a,q,b)
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
q=m.aR(a,b,s)
for(p=s;p>q;p=o){o=p-1
m.b0(a,p,m.ao(a,o))
r=m.Q
r===$&&A.b()
n=l.getInt32(r+p*4,!1)
l.$flags&2&&A.i(l,8)
l.setInt32(r+(p+1)*4,n,!1)}m.b0(a,q,b)
r=m.Q
r===$&&A.b()
l.$flags&2&&A.i(l,8)
l.setInt32(r+(q+1)*4,c,!1)
l.$flags&2&&A.i(l,10)
l.setUint16(2,s+1,!1)
return a.d=!0},
aR(a,b,c){var s,r,q,p,o
if(this.c===1){s=b[0]
r=c-1
for(q=0;q<=r;){p=B.c.a3(q+r,2)
o=a.c
o===$&&A.b()
if(o.getFloat64(4+p*8,!1)<s)q=p+1
else r=p-1}return q}r=c-1
for(q=0;q<=r;){p=B.c.a3(q+r,2)
if(this.aA(this.ao(a,p),b)<0)q=p+1
else r=p-1}return q},
ao(a,b){var s,r,q,p=A.a([],t.n),o=this.z
o===$&&A.b()
s=4+b*o
for(o=this.c,r=0;r<o;++r){q=a.c
q===$&&A.b()
p.push(q.getFloat64(s+r*8,!1))}return p},
b0(a,b,c){var s,r,q,p,o=this.z
o===$&&A.b()
s=4+b*o
for(o=this.c,r=0;r<o;++r){q=r<c.length?c[r]:0
p=a.c
p===$&&A.b()
p.$flags&2&&A.i(p,13)
p.setFloat64(s+r*8,q,!1)}},
fn(b4,b5,b6,b7,b8){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2=this,b3=b5.length
if(b3===0)return
b2.r=null
A.cd("insertSortedBatchSync total = "+b3+", K = "+b7)
s=A.a([],t.t)
r=b2.d
for(q=b2.a,p=b2.b;r!==-1;r=l){s.push(r)
o=q.C(p,r).c
o===$&&A.b()
if(o.getUint8(1)===1){q.u(p,r,!1)
break}n=o.getUint16(2,!1)
m=b2.Q
m===$&&A.b()
l=o.getInt32(m+n*4,!1)
q.u(p,r,!1)}if(b7===1){k=B.b.gV(s)
o=q.C(p,k).c
o===$&&A.b()
j=o.getUint16(2,!1)
i=j>0?o.getFloat64(4+(j-1)*8,!1):-1/0
for(m=b3===1e4,h=b8!=null,g=o,f=!1,e=0;e<b3;++e,f=a0){d=h?b8[e]:e
c=b4[d]
b=b5[d]
a=b6[d]
o=b2.y
o===$&&A.b()
a0=j<o&&c>=i
if(a0){g.$flags&2&&A.i(g,13)
g.setFloat64(4+j*8,c,!1)
o=b2.Q
o===$&&A.b()
g.setInt32(o+j*4,b,!1)
o=b2.as
o===$&&A.b()
g.setUint16(o+j*2,a,!1);++j
i=c
continue}g.$flags&2&&A.i(g,10)
g.setUint16(2,j,!1)
q.u(p,k,f)
b2.h4(s,c,b,a)
a1=B.b.gV(s)
if(m){a2="Split old leaf "+k+", path.last is now "+a1
a3=$.pk
if(a3==null)A.op(a2)
else a3.$1(a2)}o=q.C(p,a1).c
o===$&&A.b()
j=o.getUint16(2,!1)
i=j>0?o.getFloat64(4+(j-1)*8,!1):-1/0
g=o
k=a1}g.$flags&2&&A.i(g,10)
g.setUint16(2,j,!1)
q.u(p,k,f)}else{k=B.b.gV(s)
a4=q.C(p,k)
for(o=t.n,m=b8!=null,f=!1,e=0;e<b3;++e){d=m?b8[e]:e
a5=A.a(new Array(b7),o)
for(h=d*b7,a6=0;a6<b7;++a6)a5[a6]=b4[h+a6]
b=b5[d]
a=b6[d]
h=a4.c
h===$&&A.b()
j=h.getUint16(2,!1)
h=b2.y
h===$&&A.b()
if(j<h){if(j>0){h=b2.aA(a5,b2.ao(a4,j-1))
a7=h>=0}else a7=!0
if(a7){b2.b9(a4,a5,b,a)
f=!0
continue}}q.u(p,k,f)
b2.b4(a5,b,a)
B.b.v(s)
a8=b2.d
for(;a8!==-1;a8=b1){s.push(a8)
h=q.C(p,a8).c
h===$&&A.b()
if(h.getUint8(1)===1){q.u(p,a8,!1)
break}a9=h.getUint16(2,!1)
b0=b2.Q
b0===$&&A.b()
b1=h.getInt32(b0+a9*4,!1)
q.u(p,a8,!1)}k=B.b.gV(s)
a4=q.C(p,k)
f=!1}q.u(p,k,f)}if(s.length!==0)b2.e=B.b.gV(s)},
iN(a,b,c,d){return this.fn(a,b,c,d,null)},
h4(a0,a1,a2,a3){var s,r,q,p,o,n,m,l,k,j,i,h=this,g=B.b.gV(a0),f=h.a,e=h.b,d=f.C(e,g),c=f.a_(e).a4(),b=f.C(e,c),a=b.c
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
if(a1>=i)h.es(b,a1,a2,a3)
else h.es(d,a1,a2,a3)
f.u(e,g,!0)
f.u(e,c,!0)
h.eN(a0,a0.length-1,i,c)},
es(a,b,c,d){var s,r,q,p,o,n,m,l,k=this,j=a.c
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
eN(a2,a3,a4,a5){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1=this
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
a1.dn(p)
B.b.dC(a2,0,p)
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
a1.eN(a2,r,f,i)}},
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
A.h2.prototype={}
A.eW.prototype={
am(){return A.a7(["name",this.a,"sql",this.b],t.N,t.z)}}
A.ex.prototype={
am(){return A.a7(["name",this.a,"sql",this.b],t.N,t.z)}}
A.cV.prototype={
am(){var s=this
return A.a7(["name",s.a,"timing",s.b,"event",s.c,"tableName",s.d,"forEachRow",s.e,"sql",s.f],t.N,t.z)}}
A.br.prototype={
am(){return A.a7(["name",this.a,"condition",A.R(this.b)],t.N,t.z)}}
A.c6.prototype={
fV(a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,a0,a1,a2,a3,a4,a5){var s,r=this,q=r.b,p=A.z(q).i("h<1,e>")
q=A.r(new A.h(q,new A.mT(),p),p.i("u.E"))
r.dx!==$&&A.bc()
r.dx=q
p=A.o(t.N,t.S)
for(s=0;s<q.length;++s)p.k(0,q[s],s)
r.fx!==$&&A.bc()
r.fx=p
q=B.b.b1(r.r,new A.mU())
r.dy!==$&&A.bc()
r.dy=q
q=B.b.b1(r.e,new A.mV())||B.b.b1(r.f,new A.mW())
r.fr!==$&&A.bc()
r.fr=q},
am(){var s,r,q,p=this,o=p.c,n=A.z(o).i("h<1,l>")
o=A.r(new A.h(o,new A.mX(),n),n.i("u.E"))
n=p.y
s=A.z(n).i("h<1,e?>")
n=A.r(new A.h(n,new A.mY(),s),s.i("u.E"))
s=p.z
r=A.z(s).i("h<1,e?>")
s=A.r(new A.h(s,new A.mZ(),r),r.i("u.E"))
r=p.Q
q=A.z(r).i("h<1,w<e,@>>")
r=A.r(new A.h(r,new A.n_(),q),q.i("u.E"))
return A.a7(["name",p.a,"columnNames",p.b,"columnTypes",o,"isColumnar",p.d,"isForeign",p.at,"foreignServer",p.ax,"foreignOptions",p.ay,"columnPrimaryKey",p.e,"columnUnique",p.f,"columnReferencesTable",p.r,"columnReferencesColumn",p.w,"columnOnDeleteCascade",p.x,"columnDefaultValues",n,"columnCheckExpressions",s,"policies",r,"partitionByColumn",p.ch,"partitionOfParent",p.CW,"partitionFromValue",p.cx,"partitionToValue",p.cy,"partitionChildren",p.db],t.N,t.z)}}
A.mT.prototype={
$1(a){return a.toLowerCase()},
$S:7}
A.mU.prototype={
$1(a){return a!=null},
$S:150}
A.mV.prototype={
$1(a){return a},
$S:48}
A.mW.prototype={
$1(a){return a},
$S:48}
A.mX.prototype={
$1(a){return a.a},
$S:102}
A.mY.prototype={
$1(a){return a!=null?A.R(a):null},
$S:49}
A.mZ.prototype={
$1(a){return a!=null?A.R(a):null},
$S:49}
A.n_.prototype={
$1(a){return a.am()},
$S:104}
A.mP.prototype={
$1(a){if(a==null)return null
return new A.c3(new A.c1(A.is(a)).bt()).M()},
$S:50}
A.mQ.prototype={
$1(a){if(a==null)return null
return new A.c3(new A.c1(A.is(a)).bt()).M()},
$S:50}
A.mR.prototype={
$1(a){return B.cH[a]},
$S:106}
A.mS.prototype={
$1(a){var s=new A.c3(new A.c1(a.h(0,"condition")).bt()).M()
return new A.br(a.h(0,"name"),s)},
$S:107}
A.dP.prototype={
am(){var s=this
return A.a7(["name",s.a,"fromTable",s.b,"toTable",s.c,"fromKey",s.d,"toKey",s.e],t.N,t.z)}}
A.b8.prototype={
am(){var s=this
return A.a7(["name",s.a,"tableName",s.b,"columnName",s.c,"usingMethod",s.d],t.N,t.z)}}
A.iB.prototype={
cM(a,b,c){var s=this.z,r=A.E(s).i("b0<2>"),q=r.i("aJ<F.E>")
s=A.r(new A.aJ(new A.b0(s,r),new A.iG(a.toLowerCase(),b.toUpperCase(),c.toUpperCase()),q),q.i("F.E"))
return s},
fJ(a,b,c){var s=c.toLowerCase(),r=this.w.J(a.toLowerCase(),new A.iH()).J(b.toLowerCase(),new A.iI()),q=J.X(r)
if(!q.E(r,s))q.R(r,s)
this.aF()},
c_(a,b,c){var s,r,q,p=a.toLowerCase()
if(p==="admin"||p==="sa")return!0
s=this.w.h(0,p)
if(s==null)return!1
r=s.h(0,b.toLowerCase())
if(r==null)return!1
q=J.X(r)
return q.E(r,c.toLowerCase())||q.E(r,"all")},
dO(){var s=this,r=t.N
return A.a7(["tables",A.Z(s.c,r,t.eT),"relationships",A.Z(s.d,r,t.fM),"indexes",A.Z(s.e,r,t._),"stats",s.f.dG(0,new A.iC(),r,t.h2),"procedures",A.Z(s.x,r,t.eO),"functions",A.Z(s.y,r,t.d5),"triggers",A.Z(s.z,r,t.f6)],r,t.z)},
dK(a){var s=this,r="relationships",q="procedures",p="functions",o="triggers"
s.r.v(0)
s.c.v(0)
if(a.h(0,"tables")!=null)t.f.a(a.h(0,"tables")).a1(0,new A.iJ(s))
s.d.v(0)
if(a.h(0,r)!=null)t.f.a(a.h(0,r)).a1(0,new A.iK(s))
s.e.v(0)
if(a.h(0,"indexes")!=null)t.f.a(a.h(0,"indexes")).a1(0,new A.iL(s))
s.f.v(0)
if(a.h(0,"stats")!=null)t.f.a(a.h(0,"stats")).a1(0,new A.iM(s))
s.x.v(0)
if(a.h(0,q)!=null)t.f.a(a.h(0,q)).a1(0,new A.iN(s))
s.y.v(0)
if(a.h(0,p)!=null)t.f.a(a.h(0,p)).a1(0,new A.iO(s))
s.z.v(0)
if(a.h(0,o)!=null)t.f.a(a.h(0,o)).a1(0,new A.iP(s))},
aX(a){return this.f.J(a.toLowerCase(),new A.iF())},
bo(a,b){this.c.k(0,a.a.toLowerCase(),a)
if(b)this.aF()},
f4(a,b){this.e.k(0,a.a.toLowerCase(),a)
this.r.v(0)
if(b)this.aF()},
bu(a){var s=a.toLowerCase()
return this.r.J(s,new A.iE(this,s))},
b5(a,b){var s,r,q=a.toLowerCase(),p=b.toLowerCase()
for(s=this.e,s=new A.an(s,s.r,s.e,A.E(s).i("an<2>"));s.p();){r=s.d
if(r.b.toLowerCase()===q&&r.c.toLowerCase()===p)return r}return null},
dF(){var s=0,r=A.b5(t.H),q
var $async$dF=A.b6(function(a,b){if(a===1)return A.b2(b,r)
for(;;)switch(s){case 0:s=1
break
case 1:return A.b3(q,r)}})
return A.b4($async$dF,r)},
aF(){return}}
A.iG.prototype={
$1(a){return a.d.toLowerCase()===this.a&&a.b.toUpperCase()===this.b&&a.c.toUpperCase()===this.c},
$S:108}
A.iH.prototype={
$0(){return A.o(t.N,t.dy)},
$S:109}
A.iI.prototype={
$0(){return A.a([],t.s)},
$S:110}
A.iC.prototype={
$2(a,b){return new A.aj(a,A.qo(b.am()),t.aS)},
$S:111}
A.iJ.prototype={
$2(a,b){if(b instanceof A.c6)this.a.c.k(0,J.x(a),b)
else if(t.f.b(b))this.a.c.k(0,J.x(a),A.tQ(A.Z(b,t.N,t.z)))},
$S:4}
A.iK.prototype={
$2(a,b){if(b instanceof A.dP)this.a.d.k(0,J.x(a),b)
else if(t.f.b(b))this.a.d.k(0,J.x(a),A.tJ(A.Z(b,t.N,t.z)))},
$S:4}
A.iL.prototype={
$2(a,b){if(b instanceof A.b8)this.a.e.k(0,J.x(a),b)
else if(t.f.b(b))this.a.e.k(0,J.x(a),A.th(A.Z(b,t.N,t.z)))},
$S:4}
A.iM.prototype={
$2(a,b){if(b instanceof A.bt)this.a.f.k(0,J.x(a),b)
else if(t.f.b(b))this.a.f.k(0,J.x(a),A.qo(A.Z(b,t.N,t.z)))},
$S:4}
A.iN.prototype={
$2(a,b){if(b instanceof A.eW)this.a.x.k(0,J.x(a),b)
else if(t.f.b(b))this.a.x.k(0,J.x(a),A.tE(A.Z(b,t.N,t.z)))},
$S:4}
A.iO.prototype={
$2(a,b){if(b instanceof A.ex)this.a.y.k(0,J.x(a),b)
else if(t.f.b(b))this.a.y.k(0,J.x(a),A.tb(A.Z(b,t.N,t.z)))},
$S:4}
A.iP.prototype={
$2(a,b){if(b instanceof A.cV)this.a.z.k(0,J.x(a),b)
else if(t.f.b(b))this.a.z.k(0,J.x(a),A.tR(A.Z(b,t.N,t.z)))},
$S:4}
A.iF.prototype={
$0(){return A.qn(0)},
$S:112}
A.iE.prototype={
$0(){var s=this.a.e,r=A.E(s).i("b0<2>"),q=r.i("aJ<F.E>")
s=A.r(new A.aJ(new A.b0(s,r),new A.iD(this.b),q),q.i("F.E"))
return s},
$S:113}
A.iD.prototype={
$1(a){return a.b.toLowerCase()===this.a},
$S:114}
A.bq.prototype={
am(){return A.a7(["min",this.a,"max",this.b,"distinctCount",this.c],t.N,t.z)}}
A.df.prototype={
ix(a){var s=this.a
if(s.length===0)return 0.05
if(a<B.b.gH(s))return 0.01
if(a>B.b.gV(this.a))return 0.01
return 1/this.a.length},
am(){return A.a7(["buckets",this.a],t.N,t.z)}}
A.bt.prototype={
am(){var s=t.N,r=t.a
return A.a7(["rowCount",this.a,"columnStats",this.b.dG(0,new A.n2(),s,r),"histograms",this.c.dG(0,new A.n3(),s,r)],s,t.z)}}
A.n2.prototype={
$2(a,b){return new A.aj(a,b.am(),t.aw)},
$S:115}
A.n3.prototype={
$2(a,b){return new A.aj(a,A.a7(["buckets",b.a],t.N,t.z),t.aw)},
$S:116}
A.n0.prototype={
$2(a,b){var s=b.h(0,"min"),r=b.h(0,"max"),q=b.h(0,"distinctCount")
if(q==null)q=0
this.a.b.k(0,a,new A.bq(s,r,q))},
$S:51}
A.n1.prototype={
$2(a,b){var s,r,q=b.h(0,"buckets")
if(q==null)q=[]
s=t.i
q=A.a6(q,!0,s)
r=new A.df(A.a([],t.n))
r.a=A.a6(q,!0,s)
this.a.c.k(0,a,r)},
$S:51}
A.bH.prototype={
am(){return A.a7(["p",this.a,"s",this.b],t.N,t.z)}}
A.hh.prototype={
ap(){B.a.U(this.a,":memory:")
return},
bg(){B.a.U(this.a,":memory:")
return},
iv(a,b,c){var s,r,q,p,o,n=A.rf(a)
for(s=n.length,r=this.b,q=0;q<n.length;n.length===s||(0,A.n)(n),++q){p=r.J(n[q],new A.j9())
o=J.bb(p)
if(!o.b1(p,new A.ja(b,c)))o.R(p,new A.bH(b,c))}this.bg()},
bi(a){var s,r,q,p,o,n,m=A.rf(a),l=m.length
if(l===0)return A.a([],t.x)
for(s=this.b,r=t.ec,q=null,p=0;p<m.length;m.length===l||(0,A.n)(m),++p){o=s.h(0,m[p])
if(o==null||J.pD(o))return A.a([],t.x)
if(q==null)q=A.a6(o,!0,r)
else{n=A.z(q).i("aJ<1>")
q=A.r(new A.aJ(q,new A.jc(o),n),n.i("F.E"))}}return q==null?A.a([],t.x):q}}
A.j9.prototype={
$0(){return A.a([],t.x)},
$S:118}
A.ja.prototype={
$1(a){return a.a===this.a&&a.b===this.b},
$S:31}
A.jc.prototype={
$1(a){return J.rJ(this.a,new A.jb(a))},
$S:31}
A.jb.prototype={
$1(a){var s=this.a
return a.a===s.a&&a.b===s.b},
$S:31}
A.cK.prototype={
am(){var s=this
return A.a7(["id",s.a,"vector",s.b.a,"pageId",s.c,"slotId",s.d,"neighbors",s.e],t.N,t.z)}}
A.jx.prototype={
ap(){B.a.U(this.a,":memory:")
return},
bg(){B.a.U(this.a,":memory:")
return},
bv(a,b){switch(this.w.toLowerCase()){case"cosine":return a.cl(b)
case"dot":return a.cn(b)
case"euclidean":default:return a.cm(b)}},
b4(a0,a1,a2){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d=this,c=d.x,b=c.length,a=d.Q.fp()
if(a===0)a=1e-7
s=B.h.dA(-Math.log(a)*d.f)
r=s+1
q=J.dz(r,t.bW)
for(p=t.t,o=0;o<r;++o)q[o]=A.a([],p)
c.push(new A.cK(b,a0,a1,a2,q))
n=d.y
if(n==null){d.y=b
d.z=s
return}m=d.z
for(l=m;l>s;--l)n=d.eX(a0,n,l)
k=s<m?s:m
j=A.a([n],p)
for(l=k;l>=0;--l,j=i){i=d.ii(a0,j,64,l)
h=d.ij(a0,i,l===0?32:16)
for(p=h.length,g=0;g<h.length;h.length===p||(0,A.n)(h),++g){f=h[g]
e=c[f]
J.ae(q[l],f)
J.ae(e.e[l],b)}}if(s>d.z){d.y=b
d.z=s}},
eX(a,b,c){var s,r,q,p,o,n=this.x,m=this.bv(n[b].b,a)
for(s=b,r=!0;r;){q=n[s].e
r=!1
if(c<q.length)for(q=J.au(q[c]);q.p();){p=q.gF()
o=this.bv(n[p].b,a)
if(o<m){m=o
s=p
r=!0}}}return s},
eW(a,a0,a1,a2,a3){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d=A.oV(a0,t.S),c=t.g5,b=A.a([],c)
for(s=a0.length,r=this.x,q=0;q<a0.length;a0.length===s||(0,A.n)(a0),++q){p=a0[q]
b.push(new A.ay(p,this.bv(r[p].b,a)))}B.b.ar(b,new A.jy())
o=A.a([],c)
for(c=b.length,s=a3!=null,q=0;q<b.length;b.length===c||(0,A.n)(b),++q){n=b[q]
m=r[n.a]
if(!s||a3.$2(m.c,m.d))o.push(n)}while(b.length!==0){l=B.b.aM(b,0)
if(o.length!==0){k=B.b.gV(o)
if(o.length>=a1&&l.b>k.b)break}c=r[l.a].e
if(a2<c.length)for(c=J.au(c[a2]);c.p();){j=c.gF()
if(!d.E(0,j)){d.R(0,j)
i=this.bv(r[j].b,a)
if(o.length===0||i<B.b.gV(o).b||o.length<a1){h=new A.ay(j,i)
g=B.b.cu(b,new A.jz(i))
if(g===-1)b.push(h)
else B.b.dC(b,g,h)
f=r[j]
if(!s||a3.$2(f.c,f.d)){e=B.b.cu(o,new A.jA(i))
if(e===-1)o.push(h)
else B.b.dC(o,e,h)
if(o.length>a1)o.pop()}}}}}d=t.cw
d=A.r(new A.h(o,new A.jB(),d),d.i("u.E"))
return d},
ii(a,b,c,d){return this.eW(a,b,c,d,null)},
ij(a,b,c){var s,r,q
if(b.length<=c)return b
s=A.z(b).i("h<1,ay>")
r=A.r(new A.h(b,new A.jC(this,a),s),s.i("u.E"))
B.b.ar(r,new A.jD())
s=A.hQ(r,0,A.cz(c,"count",t.S),A.z(r).c)
q=s.$ti.i("h<u.E,l>")
s=A.r(new A.h(s,new A.jE(),q),q.i("u.E"))
return s},
cP(a,b,c){var s,r,q,p,o,n,m,l=this
if(l.x.length===0||l.y==null)return A.a([],t.ae)
s=l.y
s.toString
r=l.z
for(q=r,p=s;q>0;--q)p=l.eX(a,p,q)
s=A.a([p],t.t)
o=l.eW(a,s,32>b?32:b,0,c)
s=A.z(o).i("h<1,ay>")
n=A.r(new A.h(o,new A.jF(l,a),s),s.i("u.E"))
B.b.ar(n,new A.jG())
s=A.hQ(n,0,A.cz(b,"count",t.S),A.z(n).c)
m=s.$ti.i("h<u.E,cK>")
s=A.r(new A.h(s,new A.jH(l),m),m.i("u.E"))
return s}}
A.jy.prototype={
$2(a,b){return B.h.A(a.b,b.b)},
$S:17}
A.jz.prototype={
$1(a){return a.b>this.a},
$S:54}
A.jA.prototype={
$1(a){return a.b>this.a},
$S:54}
A.jB.prototype={
$1(a){return a.a},
$S:55}
A.jC.prototype={
$1(a){var s=this.a
return new A.ay(a,s.bv(s.x[a].b,this.b))},
$S:56}
A.jD.prototype={
$2(a,b){return B.h.A(a.b,b.b)},
$S:17}
A.jE.prototype={
$1(a){return a.a},
$S:55}
A.jF.prototype={
$1(a){var s=this.a
return new A.ay(a,s.bv(s.x[a].b,this.b))},
$S:56}
A.jG.prototype={
$2(a,b){return B.h.A(a.b,b.b)},
$S:17}
A.jH.prototype={
$1(a){return this.a.x[a.a]},
$S:124}
A.ay.prototype={}
A.bo.prototype={
am(){return A.a7(["vector",this.a.a,"pageId",this.b,"slotId",this.c],t.N,t.z)}}
A.ho.prototype={
ap(){B.a.U(this.a,":memory:")
return},
jf(){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4=this,a5=a4.w,a6=a5.length
if(a6===0)return
s=a4.d
a6=s>a6?a6:s
if(a6<1)a6=1
r=new A.id()
r.dT(42)
q=A.a6(a5,!0,t.b1)
B.b.fP(q,r)
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
bg(){if(this.w.length!==0)this.jf()
B.a.U(this.a,":memory:")
return},
bA(a,b){switch(this.c.toLowerCase()){case"cosine":return a.cl(b)
case"dot":return a.cn(b)
case"euclidean":default:return a.cm(b)}},
b4(a,b,c){var s,r,q,p,o=this,n=new A.bo(a,b,c),m=o.f
if(m.length===0)o.w.push(n)
else{for(s=0,r=1/0,q=0;q<m.length;++q){p=o.bA(a,m[q])
if(p<r){r=p
s=q}}J.ae(o.r.J(s,new A.kV()),n)}},
cP(a,b,c){var s,r,q,p,o,n,m,l,k,j,i,h,g,f=this,e="count",d=f.f
if(d.length===0){s=A.a([],t.bo)
for(d=f.w,r=d.length,q=c!=null,p=0;p<d.length;d.length===r||(0,A.n)(d),++p){o=d[p]
if(!q||c.$2(o.b,o.c))s.push(new A.bv(o,f.bA(o.a,a)))}B.b.ar(s,new A.kW())
d=A.hQ(s,0,A.cz(b,e,t.S),t.fj)
r=d.$ti.i("h<u.E,bo>")
d=A.r(new A.h(d,new A.kX(),r),r.i("u.E"))
return d}n=A.a([],t.cg)
for(m=0;m<d.length;++m)n.push(new A.bE(m,f.bA(d[m],a)))
B.b.ar(n,new A.kY())
d=t.S
r=A.hQ(n,0,A.cz(f.e,e,d),t.cY)
q=r.$ti.i("h<u.E,l>")
l=A.r(new A.h(r,new A.kZ(),q),q.i("u.E"))
k=A.a([],t.bo)
for(r=l.length,q=f.r,j=c!=null,p=0;p<l.length;l.length===r||(0,A.n)(l),++p){i=q.h(0,l[p])
if(i!=null)for(h=J.au(i);h.p();){g=h.gF()
if(!j||c.$2(g.b,g.c))k.push(new A.bv(g,f.bA(g.a,a)))}}B.b.ar(k,new A.l_())
d=A.hQ(k,0,A.cz(b,e,d),t.fj)
r=d.$ti.i("h<u.E,bo>")
d=A.r(new A.h(d,new A.l0(),r),r.i("u.E"))
return d}}
A.kV.prototype={
$0(){return A.a([],t.D)},
$S:125}
A.kW.prototype={
$2(a,b){return B.h.A(a.b,b.b)},
$S:41}
A.kX.prototype={
$1(a){return a.a},
$S:38}
A.kY.prototype={
$2(a,b){return B.h.A(a.b,b.b)},
$S:128}
A.kZ.prototype={
$1(a){return a.a},
$S:129}
A.l_.prototype={
$2(a,b){return B.h.A(a.b,b.b)},
$S:41}
A.l0.prototype={
$1(a){return a.a},
$S:38}
A.bv.prototype={}
A.bE.prototype={}
A.mH.prototype={
$1(a){return a.al()},
$S:130}
A.mI.prototype={
$2(a,b){return a+b.length},
$S:131}
A.cp.prototype={
dP(){var s=this,r=s.f
return r==null?s.f=s.a.bf(s.c+"/"+s.b+".db"):r},
bE(){var s,r,q=this
if(q.r!=null){s=q.a
r=q.c+"/"+q.b+".db"
s.iZ(r,q.w)
s.u(r,q.w,!0)
q.r=null
q.w=-1
if(s.gab()==null){s=s.gaI()
if(s!=null)s.bZ()}}q.f=null},
iM(a){var s,r,q,p,o,n,m,l,k=this
if(k.r!=null){k.a.br(k.c+"/"+k.b+".db",k.w)
s=k.r
s.toString
if(A.cT(s,a,a.length)){k.r.d=!0
return}k.bE()}r=k.dP()
if(r===0){s=k.a
q=k.c+"/"+k.b+".db"
p=s.C(q,0)
s.br(q,0)
A.fe(p)
A.cT(p,a,a.length)
p.d=!0
k.r=p
k.w=0
k.f=1
return}o=r-1
s=k.a
q=k.c+"/"+k.b+".db"
n=s.C(q,o)
s.br(q,o)
m=a.length
if(A.cT(n,a,m)){n.d=!0
k.r=n
k.w=o}else{s.u(q,o,!1)
l=s.C(q,r)
s.br(q,r)
A.fe(l)
A.cT(l,a,m)
l.d=!0
k.r=l
k.w=r
k.f=r+1}},
fo(a,b){var s,r,q,p,o,n,m=this,l=$.ow(),k=m.d
k===$&&A.b()
s=A.tI(l,a,b,0,0,k)
if(m.r!=null){m.a.br(m.c+"/"+m.b+".db",m.w)
k=m.r
k.toString
if(A.cT(k,l,s)){l=m.r
l.d=!0
l=A.fd(l)
return new A.aY(m.w,l-1)}m.bE()}r=m.dP()
if(r===0){k=m.a
q=m.c+"/"+m.b+".db"
p=k.C(q,0)
k.br(q,0)
A.fe(p)
A.cT(p,l,s)
p.d=!0
m.r=p
m.w=0
m.f=1
return new A.aY(0,0)}o=r-1
k=m.a
q=m.c+"/"+m.b+".db"
p=k.C(q,o)
k.br(q,o)
if(A.cT(p,l,s)){p.d=!0
l=A.fd(p)
m.r=p
m.w=o
return new A.aY(o,l-1)}else{k.u(q,o,!1)
n=k.C(q,r)
A.fe(n)
A.cT(n,l,s)
n.d=!0
l=A.fd(n)
m.r=n
m.w=r
m.f=r+1
return new A.aY(r,l-1)}},
dw(a,b,c){var s,r,q,p,o,n,m=this.a,l=this.c+"/"+this.b+".db",k=m.C(l,a),j=A.ab(k,b)
if(j!=null)try{s=A.aV(j)
r=new A.cm(s.a,c,s.c,s.d)
q=5+b*4
o=k.c
o===$&&A.b()
p=o.getUint16(q,!1)
B.j.aj(k.b,p,r.al())
m.u(l,a,!0)}catch(n){m.u(l,a,!1)}else m.u(l,a,!1)},
c1(a,b,c,d,e,f){var s,r,q,p,o=this
o.bE()
s=o.a
r=o.c+"/"+o.b+".db"
q=s.bf(r)
p=f==null?s.ax:f
return new A.hM(s,r,q,p,c,a==null?B.u:a,e,o,d,b)},
fL(){var s=null
return this.c1(s,s,0,s,s,s)},
fN(a,b,c,d){return this.c1(a,null,b,c,null,d)},
fM(a){var s=null
return this.c1(s,s,0,a,s,s)},
eb(a,b,c,a0){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d
if(b.length===0)return B.cI
s=A.aq(a,0,null)
r=s.getUint16(0,!1)
q=a0==null?r:a0
if(c!=null&&c.length===q){B.b.bD(c,0,q,new A.d())
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
i=new A.d2(!1).bK(d,0,null,!0)
n&2&&A.i(p)
p[k]=new A.m(i)}else if(g===7){f=s.getUint32(j+1,!1)
e=s.getUint32(j+5,!1)
i=this.d
i===$&&A.b()
d=i.cE(f,e)
n&2&&A.i(p)
p[k]=new A.L(null,d)}else{i=A.bV(s,j,h)
n&2&&A.i(p)
p[k]=i}}}else if(k<q){n&2&&A.i(p)
p[k]=new A.d()}}return p}}
A.hM.prototype={
gI(a){return this},
gF(){var s=this.ax
s.toString
return s},
p(){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c=this
for(s=c.c,r=c.a,q=c.b,p=c.d,o=c.e,n=c.f,m=c.y,l=m!=null;k=c.z,k<s;){if(c.Q==null){k=c.Q=r.C(q,k)
j=k.w
if(j==null){j=k.c
j===$&&A.b()
j=k.w=j.getUint16(1,!1)
k=j}else k=j
c.as=k
c.at=0}while(k=c.at,k<c.as){j=c.Q
j.toString
c.at=k+1
i=A.ab(j,k)
if(i!=null){k=i.length
if(k>=12){h=A.aq(i,0,null)
g=h.getUint32(0,!1)
f=h.getUint32(4,!1)
if(l)if(g<=m)e=f===0||f>m
else e=!1
else e=p.aD(g,f,o,n)
if(e){d=J.bk(B.j.gai(i),i.byteOffset+12,k-12)
s=c.r
r=c.x
q=c.w
if(s!=null)c.ax=c.ay=q.eb(d,s,c.ay,r)
else{s=q.d
s===$&&A.b()
c.ax=A.a4(d,r,s)}return!0}}else{s=c.r
r=c.x
q=c.w
if(s!=null)c.ax=c.ay=q.eb(i,s,c.ay,r)
else{s=q.d
s===$&&A.b()
c.ax=A.a4(i,r,s)}return!0}}}r.u(q,c.z,!1)
c.Q=null;++c.z}c.ax=null
return!1},
$ia1:1}
A.bS.prototype={
iO(a){var s,r,q,p,o,n,m,l,k,j,i
for(s=a.length,r=this.a,q=this.c+"/"+this.b+".col_",p=0;p<s;++p){o=q+p
n=a[p].al()
m=r.bf(o)
if(m===0){l=r.C(o,0)
A.fe(l)
A.p3(l,n)
r.u(o,0,!0)
continue}k=m-1
j=A.p3(r.C(o,k),n)
r.u(o,k,j)
if(!j){i=r.C(o,m)
A.fe(i)
A.p3(i,n)
r.u(o,m,!0)}}},
cO(a){return new A.cx(this.fK(a),t.fC)},
fK(a){var s=this
return function(){var r=a
var q=0,p=1,o=[],n,m,l,k,j,i,h,g,f
return function $async$cO(b,c,d){if(c===1){o.push(d)
q=p}for(;;)switch(q){case 0:h=s.c+"/"+s.b+".col_"+r
g=s.a
f=g.bf(h)
n=0
case 2:if(!(n<f)){q=4
break}m=g.C(h,n)
l=m.w
if(l==null){k=m.c
k===$&&A.b()
l=m.w=k.getUint16(1,!1)}j=0
case 5:if(!(j<l)){q=7
break}i=A.ab(m,j)
q=i!=null?8:9
break
case 8:q=10
return b.b=A.bV(A.aq(i,0,null),0,i.length),1
case 10:case 9:case 6:++j
q=5
break
case 7:g.u(h,n,!1)
case 3:++n
q=2
break
case 4:return 0
case 1:return b.c=o.at(-1),3}}}}}
A.fk.prototype={
dN(a){var s,r,q,p,o,n,m,l=this.a,k=this.b+"/"+this.c+"_toast.db",j=l.a_(k).a4(),i=a.length
for(s=j,r=0;i>0;){q=l.C(k,s)
p=q.c
p===$&&A.b()
o=i>4090
n=o?4090:i
m=o?s+1:4294967295
p.$flags&2&&A.i(p,11)
p.setUint32(0,m,!1)
p.setUint16(4,n,!1)
B.j.aG(q.b,6,6+n,a,r)
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
B.j.a8(n,j,o,new Uint8Array(r.subarray(6,A.pe(6,6+p,r.length))))
m.u(l,k,!1)
j=o
k=q}return n}}
A.hS.prototype={
cD(a){return this.j7(a)},
j7(a){var s=0,r=A.b5(t.hd),q,p=this,o,n
var $async$cD=A.b6(function(b,c){if(b===1)return A.b2(c,r)
for(;;)switch(s){case 0:n=p.b
n===$&&A.b()
s=3
return A.as(n.cs(a),$async$cD)
case 3:o=c
q=new A.hb(o.a,o.b,o.c)
s=1
break
case 1:return A.b3(q,r)}})
return A.b4($async$cD,r)}}
A.hb.prototype={
gt(a){return this.b.length}}
A.on.prototype={
$1(a){return A.tc(A.o8(a))},
$S:132}
A.oa.prototype={
$1(a){var s=J.bG(a,new A.o9(),t.N)
s=A.r(s,s.$ti.i("u.E"))
return s},
$S:133}
A.o9.prototype={
$1(a){var s
if(a instanceof A.d)s="NULL"
else{s=a.ga2()
s=s==null?null:J.x(s)
if(s==null)s="NULL"}return s},
$S:18};(function aliases(){var s=J.cl.prototype
s.fQ=s.l
s=A.a2.prototype
s.dS=s.aG})();(function installTearOffs(){var s=hunkHelpers._static_2,r=hunkHelpers._static_0,q=hunkHelpers._static_1,p=hunkHelpers.installStaticTearOff,o=hunkHelpers._instance_0i,n=hunkHelpers._instance_1u
s(J,"v5","tn",134)
r(A,"vi","tz",13)
q(A,"vG","tW",22)
q(A,"vH","tX",22)
q(A,"vI","tY",22)
r(A,"r_","vA",2)
p(A,"vO",5,null,["$5"],["vt"],136,0)
p(A,"vT",4,null,["$1$4","$4"],["o6",function(a,b,c,d){return A.o6(a,b,c,d,t.z)}],137,0)
p(A,"vV",5,null,["$2$5","$5"],["po",function(a,b,c,d,e){var m=t.z
return A.po(a,b,c,d,e,m,m)}],138,0)
p(A,"vU",6,null,["$3$6","$6"],["pn",function(a,b,c,d,e,f){var m=t.z
return A.pn(a,b,c,d,e,f,m,m,m)}],139,0)
p(A,"vR",4,null,["$1$4","$4"],["qU",function(a,b,c,d){return A.qU(a,b,c,d,t.z)}],140,0)
p(A,"vS",4,null,["$2$4","$4"],["qV",function(a,b,c,d){var m=t.z
return A.qV(a,b,c,d,m,m)}],141,0)
p(A,"vQ",4,null,["$3$4","$4"],["qT",function(a,b,c,d){var m=t.z
return A.qT(a,b,c,d,m,m,m)}],142,0)
p(A,"vM",5,null,["$5"],["vs"],143,0)
p(A,"vW",4,null,["$4"],["o7"],144,0)
p(A,"vL",5,null,["$5"],["vr"],145,0)
p(A,"vK",5,null,["$5"],["vq"],146,0)
p(A,"vP",4,null,["$4"],["vu"],147,0)
q(A,"vJ","vn",148)
p(A,"vN",5,null,["$5"],["qS"],149,0)
q(A,"vZ","uU",53)
o(A.fw.prototype,"gt","iW",83)
n(A.h8.prototype,"gfH","fI",69)
q(A,"wp","pv",100)
q(A,"iu","R",20)})();(function inheritance(){var s=hunkHelpers.mixin,r=hunkHelpers.inherit,q=hunkHelpers.inheritMany
r(A.A,null)
q(A.A,[A.oR,J.hm,A.f5,J.bd,A.nm,A.ah,A.a2,A.mM,A.F,A.cQ,A.eH,A.fq,A.er,A.ep,A.ev,A.hW,A.hR,A.fG,A.ef,A.d_,A.c5,A.cE,A.n6,A.lY,A.eq,A.fI,A.aa,A.lQ,A.aL,A.an,A.eG,A.dA,A.dZ,A.i1,A.dT,A.ik,A.nl,A.nV,A.bD,A.ia,A.nT,A.im,A.i2,A.ca,A.aK,A.fu,A.i4,A.dY,A.ad,A.i3,A.i8,A.ii,A.aT,A.ip,A.e_,A.iq,A.fy,A.nL,A.c9,A.fB,A.io,A.h3,A.h6,A.nJ,A.nY,A.d2,A.aw,A.bW,A.nq,A.hA,A.ff,A.nr,A.hg,A.aj,A.aE,A.il,A.bK,A.cr,A.lZ,A.ds,A.cI,A.dt,A.nF,A.id,A.j4,A.fY,A.fZ,A.j5,A.dI,A.ao,A.dJ,A.hB,A.hO,A.n5,A.cS,A.m_,A.lU,A.lV,A.cm,A.B,A.h8,A.jO,A.bu,A.cw,A.i5,A.mg,A.P,A.da,A.bC,A.mo,A.bi,A.jK,A.j7,A.k,A.y,A.aZ,A.ai,A.bp,A.dH,A.hZ,A.h7,A.ch,A.ha,A.hC,A.dQ,A.dX,A.c1,A.c3,A.N,A.iA,A.aY,A.h0,A.h2,A.eW,A.ex,A.cV,A.br,A.c6,A.dP,A.b8,A.iB,A.bq,A.df,A.bt,A.bH,A.hh,A.cK,A.jx,A.ay,A.bo,A.ho,A.bv,A.bE,A.cp,A.bS,A.fk,A.hS,A.hb])
q(J.hm,[J.eC,J.eE,J.ar,J.dB,J.dC,J.cM,J.ck])
q(J.ar,[J.cl,J.C,A.dF,A.eM])
q(J.cl,[J.hI,J.cu,J.be])
r(J.hq,A.f5)
r(J.l2,J.C)
q(J.cM,[J.eD,J.hr])
q(A.ah,[A.cO,A.c7,A.hs,A.hV,A.hN,A.i9,A.eF,A.h_,A.bz,A.fn,A.hT,A.cq,A.h5])
r(A.dW,A.a2)
r(A.de,A.dW)
q(A.F,[A.H,A.cR,A.aJ,A.bX,A.cZ,A.i0,A.ij,A.cx,A.hM])
q(A.H,[A.u,A.aB,A.b0,A.am,A.cY,A.fA])
q(A.u,[A.fi,A.h,A.f0,A.ic])
r(A.en,A.cR)
r(A.ie,A.fG)
r(A.ig,A.ie)
r(A.eh,A.ef)
q(A.c5,[A.eg,A.fH,A.fO])
r(A.bT,A.eg)
q(A.cE,[A.iQ,A.iR,A.n4,A.oi,A.ok,A.ni,A.nh,A.o_,A.jj,A.nC,A.np,A.nQ,A.nE,A.lS,A.nH,A.iX,A.iY,A.ns,A.jf,A.m4,A.mF,A.kS,A.kq,A.jT,A.jY,A.jZ,A.k_,A.k0,A.k1,A.k2,A.k3,A.k4,A.k5,A.jU,A.jV,A.jX,A.kf,A.kC,A.kK,A.kL,A.kw,A.kz,A.ky,A.ks,A.o3,A.lL,A.la,A.l9,A.lb,A.lc,A.ln,A.ly,A.lD,A.lE,A.lF,A.lG,A.lH,A.lI,A.ld,A.le,A.lf,A.lg,A.lh,A.li,A.lj,A.lk,A.ll,A.lm,A.lo,A.lp,A.lq,A.lr,A.ls,A.lt,A.lu,A.lv,A.lw,A.lx,A.lz,A.lA,A.lB,A.l3,A.l4,A.l5,A.l6,A.l7,A.l8,A.lC,A.lK,A.lJ,A.mf,A.oe,A.of,A.mK,A.mL,A.iS,A.iT,A.iU,A.jL,A.jM,A.mm,A.mn,A.jq,A.jp,A.jr,A.jo,A.jn,A.jm,A.jt,A.ju,A.lX,A.nd,A.ne,A.mJ,A.o2,A.jJ,A.jl,A.na,A.mp,A.mr,A.mq,A.mE,A.my,A.mv,A.mz,A.mA,A.mB,A.mD,A.mu,A.mt,A.mw,A.mx,A.ms,A.j8,A.j0,A.j1,A.j_,A.iZ,A.og,A.mh,A.mi,A.mj,A.mT,A.mU,A.mV,A.mW,A.mX,A.mY,A.mZ,A.n_,A.mP,A.mQ,A.mR,A.mS,A.iG,A.iD,A.ja,A.jc,A.jb,A.jz,A.jA,A.jB,A.jC,A.jE,A.jF,A.jH,A.kX,A.kZ,A.l0,A.mH,A.on,A.oa,A.o9])
q(A.iQ,[A.mk,A.nj,A.nk,A.nS,A.nR,A.ji,A.nt,A.ny,A.nx,A.nv,A.nu,A.nB,A.nA,A.nz,A.no,A.nn,A.nP,A.nO,A.o5,A.nX,A.nW,A.m0,A.m3,A.m1,A.m7,A.m2,A.m6,A.iV,A.kR,A.kT,A.kp,A.ko,A.jS,A.kB,A.kg,A.kh,A.ki,A.kj,A.kk,A.kl,A.km,A.kn,A.k7,A.k8,A.k9,A.ka,A.kD,A.kF,A.kG,A.kH,A.kI,A.kJ,A.jP,A.kx,A.jR,A.k6,A.jW,A.kr,A.kt,A.kd,A.ke,A.kM,A.kN,A.kP,A.kQ,A.jQ,A.kb,A.kc,A.oq,A.or,A.md,A.me,A.js,A.jv,A.nf,A.iH,A.iI,A.iF,A.iE,A.j9,A.kV])
r(A.eP,A.c7)
q(A.n4,[A.mO,A.eb])
q(A.aa,[A.c0,A.fx,A.ib,A.aN])
q(A.iR,[A.lM,A.oj,A.o0,A.ob,A.jk,A.nD,A.jw,A.lR,A.lT,A.nK,A.jh,A.jg,A.mb,A.mc,A.m9,A.ma,A.m8,A.m5,A.kE,A.ku,A.kv,A.kA,A.kO,A.jd,A.je,A.jN,A.mN,A.ng,A.jI,A.l1,A.n9,A.kU,A.j6,A.mC,A.iC,A.iJ,A.iK,A.iL,A.iM,A.iN,A.iO,A.iP,A.n2,A.n3,A.n0,A.n1,A.jy,A.jD,A.jG,A.kW,A.kY,A.l_,A.mI])
q(A.eM,[A.eJ,A.dG])
q(A.dG,[A.fC,A.fE])
r(A.fD,A.fC)
r(A.cn,A.fD)
r(A.fF,A.fE)
r(A.bg,A.fF)
q(A.cn,[A.hu,A.eK])
q(A.bg,[A.hv,A.eL,A.hw,A.hx,A.hy,A.eN,A.eO])
r(A.fJ,A.i9)
r(A.fs,A.fu)
r(A.ft,A.i4)
r(A.i7,A.i8)
q(A.ip,[A.i6,A.ih])
r(A.d0,A.fH)
r(A.fm,A.fO)
q(A.h3,[A.j3,A.lN])
r(A.ht,A.eF)
q(A.h6,[A.lP,A.lO,A.nc,A.hX])
r(A.nI,A.nJ)
r(A.nb,A.j3)
q(A.bz,[A.dO,A.hl])
q(A.ds,[A.fv,A.fw])
q(A.dt,[A.hF,A.hG,A.hH])
q(A.nq,[A.dV,A.av,A.db,A.f])
q(A.P,[A.dK,A.f4,A.dU,A.hj,A.hf,A.h4,A.eA,A.ci,A.co,A.bY,A.dw,A.hz,A.dS,A.i_,A.hi,A.dE,A.hL,A.cP,A.dx,A.dv,A.hk,A.hp,A.hU,A.hn,A.hd,A.h9])
q(A.k,[A.d,A.p,A.j,A.m,A.a5,A.L,A.aO,A.aG,A.bn,A.bm,A.b_,A.a8])
q(A.y,[A.M,A.e7,A.G,A.hD,A.hE])
q(A.M,[A.ag,A.aQ,A.I,A.a0,A.af,A.bM,A.cv,A.b9,A.cs,A.dR,A.dn,A.cJ,A.eI,A.dd,A.ce])
q(A.G,[A.hY,A.dk,A.dg,A.bR,A.cL,A.dp,A.fo,A.aS,A.cW,A.dy,A.dr,A.dL,A.e9,A.ez,A.fr,A.ek,A.ea,A.ee,A.f3,A.ey,A.f1,A.f8,A.f7,A.ei,A.fp,A.dj,A.dh,A.du,A.es,A.dc,A.fc,A.fa,A.di,A.cG,A.cF,A.ec,A.f_,A.f6,A.f2,A.eZ,A.eQ,A.et,A.ed,A.dl,A.em,A.cH,A.f9,A.fb,A.eS,A.fl,A.el,A.ew,A.cf,A.ej,A.eo])
r(A.dm,A.aS)
s(A.dW,A.hW)
s(A.fC,A.a2)
s(A.fD,A.ev)
s(A.fE,A.a2)
s(A.fF,A.ev)
s(A.fO,A.io)})()
var v={G:typeof self!="undefined"?self:globalThis,typeUniverse:{eC:new Map(),tR:{},eT:{},tPV:{},sEA:[]},mangledGlobalNames:{l:"int",W:"double",r9:"num",e:"String",Q:"bool",aE:"Null",t:"List",A:"Object",w:"Map",al:"JSObject"},mangledNames:{},types:["k(w<e,k>)()","k(w<e,k>)","~()","p(w<e,k>)","~(@,@)","e(l)","cp()","e(e)","Q(e)","W(e)","~(e,l)","Q(aZ)","aE()","l()","k(w<e,k>)(M)","t<w<e,k>>()","Q(w<e,k>)","l(ay,ay)","e(k)","k(M)","e(M)","e?(aZ)","~(~())","w<e,l>()","~(e,c6)","bq()","da()","d(w<e,k>)","k(k(w<e,k>))","P(aS)","e(N)","Q(bH)","l(aY,aY)","L(w<e,k>)","@()","e()","@(e)","e(k(w<e,k>))","bo(bv)","b7<B>()","e(ai)","l(bv,bv)","aE(@)","l(w<e,k>,w<e,k>)","Q(l,l)","M(M)","e(aZ)","~(A?,A?)","Q(Q)","e?(M?)","M?(@)","~(e,@)","k(@)","@(@)","Q(ay)","l(ay)","ay(l)","av(aZ)","l(e?)","~(ao,ba)","Q(ch)","ch()","t<bu>()","l(bu,bu)","l(ao,ao)","t<ao>()","Q(ao)","a5(w<e,k>)","aE(A,aW)","cf?(e)","fh<t<k>>()","+condFn,thenFn(k(w<e,k>),k(w<e,k>))(dX)","Q()","@(@,e)","Q(N)","t<W>(@)","aE(~())","~(@)","t<w<e,k>>(t<w<e,k>>)","k(w<e,k>)(ai)","aE(@,aW)","t<k(w<e,k>)>(t<M>)","t<e>(t<M>)","b7<l>()","F<e>(t<M>)","l(A?)","aE(be,be)","k(a1<k>)","Q(br)","c6()","t<k(w<e,k>)>()","l(bp,bp)","W(bp)","ai(ai)","P(P)","w<e,@>(oI)","Q(@)","W(@)","e(t<M>)","A?(A?)","@(k)","al(A,aW)","l(av)","bS()","w<e,@>(br)","l(l,l)","av(@)","br(@)","Q(cV)","w<e,t<e>>()","t<e>()","aj<e,bt>(e,bt)","bt()","t<b8>()","Q(b8)","aj<e,w<e,@>>(e,bq)","aj<e,w<e,@>>(e,df)","Q(l,ba)","t<bH>()","ba()","~(l,@)","~(A,aW)","~(ao,dI)","ai(e)","cK(ay)","t<bo>()","Q(P)","b7<~>(P)","l(bE,bE)","l(bE)","ba(k)","l(l,ba)","al(e)","t<e>(t<k>)","l(@,@)","dJ()","~(J?,ak?,J,A,aW)","0^(J?,ak?,J,0^())<A?>","0^(J?,ak?,J,0^(1^),1^)<A?,A?>","0^(J?,ak?,J,0^(1^,2^),1^,2^)<A?,A?,A?>","0^()(J,ak,J,0^())<A?>","0^(1^)(J,ak,J,0^(1^))<A?,A?>","0^(1^,2^)(J,ak,J,0^(1^,2^))<A?,A?,A?>","aK?(J,ak,J,A,aW?)","~(J?,ak?,J,~())","fj(J,ak,J,bW,~())","fj(J,ak,J,bW,~(fj))","~(J,ak,J,e)","~(e)","J(J?,ak?,J,p6?,w<A?,A?>?)","Q(e?)"],interceptorsByTag:null,leafTags:null,arrayRti:Symbol("$ti"),rttc:{"2;condFn,thenFn":(a,b)=>c=>c instanceof A.ig&&a.b(c.a)&&b.b(c.b)}}
A.uy(v.typeUniverse,JSON.parse('{"be":"cl","hI":"cl","cu":"cl","wB":"dF","eC":{"Q":[],"ac":[]},"eE":{"aE":[],"ac":[]},"ar":{"al":[]},"cl":{"ar":[],"al":[]},"C":{"t":["1"],"ar":[],"H":["1"],"al":[],"aP":["1"]},"hq":{"f5":[]},"l2":{"C":["1"],"t":["1"],"ar":[],"H":["1"],"al":[],"aP":["1"]},"bd":{"a1":["1"]},"cM":{"W":[]},"eD":{"W":[],"l":[],"ac":[]},"hr":{"W":[],"ac":[]},"ck":{"e":[],"aP":["@"],"ac":[]},"cO":{"ah":[]},"de":{"a2":["l"],"t":["l"],"H":["l"],"a2.E":"l"},"H":{"F":["1"]},"u":{"H":["1"],"F":["1"]},"fi":{"u":["1"],"H":["1"],"F":["1"],"u.E":"1","F.E":"1"},"cQ":{"a1":["1"]},"cR":{"F":["2"],"F.E":"2"},"en":{"cR":["1","2"],"H":["2"],"F":["2"],"F.E":"2"},"eH":{"a1":["2"]},"h":{"u":["2"],"H":["2"],"F":["2"],"u.E":"2","F.E":"2"},"aJ":{"F":["1"],"F.E":"1"},"fq":{"a1":["1"]},"bX":{"F":["2"],"F.E":"2"},"er":{"a1":["2"]},"ep":{"a1":["1"]},"dW":{"a2":["1"],"t":["1"],"H":["1"]},"f0":{"u":["1"],"H":["1"],"F":["1"],"u.E":"1","F.E":"1"},"ef":{"w":["1","2"]},"eh":{"ef":["1","2"],"w":["1","2"]},"cZ":{"F":["1"],"F.E":"1"},"d_":{"a1":["1"]},"eg":{"c5":["1"],"bJ":["1"],"H":["1"]},"bT":{"c5":["1"],"bJ":["1"],"H":["1"]},"eP":{"c7":[],"ah":[]},"hs":{"ah":[]},"hV":{"ah":[]},"fI":{"aW":[]},"hN":{"ah":[]},"c0":{"aa":["1","2"],"w":["1","2"],"aa.V":"2","aa.K":"1"},"aB":{"H":["1"],"F":["1"],"F.E":"1"},"aL":{"a1":["1"]},"b0":{"H":["1"],"F":["1"],"F.E":"1"},"an":{"a1":["1"]},"am":{"H":["aj<1,2>"],"F":["aj<1,2>"],"F.E":"aj<1,2>"},"eG":{"a1":["aj<1,2>"]},"dZ":{"eY":[],"dD":[]},"i0":{"F":["eY"],"F.E":"eY"},"i1":{"a1":["eY"]},"dT":{"dD":[]},"ij":{"F":["dD"],"F.E":"dD"},"ik":{"a1":["dD"]},"dF":{"ar":[],"al":[],"ac":[]},"eM":{"ar":[],"al":[]},"eJ":{"ar":[],"al":[],"ac":[]},"dG":{"bf":["1"],"ar":[],"al":[],"aP":["1"]},"cn":{"a2":["W"],"t":["W"],"bf":["W"],"ar":[],"H":["W"],"al":[],"aP":["W"]},"bg":{"a2":["l"],"t":["l"],"bf":["l"],"ar":[],"H":["l"],"al":[],"aP":["l"]},"hu":{"cn":[],"a2":["W"],"t":["W"],"bf":["W"],"ar":[],"H":["W"],"al":[],"aP":["W"],"ac":[],"a2.E":"W"},"eK":{"cn":[],"a2":["W"],"t":["W"],"bf":["W"],"ar":[],"H":["W"],"al":[],"aP":["W"],"ac":[],"a2.E":"W"},"hv":{"bg":[],"a2":["l"],"t":["l"],"bf":["l"],"ar":[],"H":["l"],"al":[],"aP":["l"],"ac":[],"a2.E":"l"},"eL":{"bg":[],"a2":["l"],"t":["l"],"bf":["l"],"ar":[],"H":["l"],"al":[],"aP":["l"],"ac":[],"a2.E":"l"},"hw":{"bg":[],"a2":["l"],"t":["l"],"bf":["l"],"ar":[],"H":["l"],"al":[],"aP":["l"],"ac":[],"a2.E":"l"},"hx":{"bg":[],"a2":["l"],"t":["l"],"bf":["l"],"ar":[],"H":["l"],"al":[],"aP":["l"],"ac":[],"a2.E":"l"},"hy":{"bg":[],"a2":["l"],"t":["l"],"bf":["l"],"ar":[],"H":["l"],"al":[],"aP":["l"],"ac":[],"a2.E":"l"},"eN":{"bg":[],"a2":["l"],"t":["l"],"bf":["l"],"ar":[],"H":["l"],"al":[],"aP":["l"],"ac":[],"a2.E":"l"},"eO":{"bg":[],"ba":[],"a2":["l"],"t":["l"],"bf":["l"],"ar":[],"H":["l"],"al":[],"aP":["l"],"ac":[],"a2.E":"l"},"i9":{"ah":[]},"fJ":{"c7":[],"ah":[]},"aK":{"ah":[]},"ca":{"a1":["1"]},"cx":{"F":["1"],"F.E":"1"},"fu":{"fh":["1"]},"fs":{"fh":["1"]},"ft":{"i4":["1"]},"ad":{"b7":["1"]},"ip":{"J":[]},"i6":{"J":[]},"ih":{"J":[]},"e_":{"ak":[]},"iq":{"p6":[]},"fx":{"aa":["1","2"],"w":["1","2"],"aa.V":"2","aa.K":"1"},"cY":{"H":["1"],"F":["1"],"F.E":"1"},"fy":{"a1":["1"]},"d0":{"c5":["1"],"bJ":["1"],"H":["1"]},"c9":{"a1":["1"]},"a2":{"t":["1"],"H":["1"]},"aa":{"w":["1","2"]},"fA":{"H":["2"],"F":["2"],"F.E":"2"},"fB":{"a1":["2"]},"c5":{"bJ":["1"],"H":["1"]},"fH":{"c5":["1"],"bJ":["1"],"H":["1"]},"fm":{"c5":["1"],"bJ":["1"],"H":["1"]},"ib":{"aa":["e","@"],"w":["e","@"],"aa.V":"@","aa.K":"e"},"ic":{"u":["e"],"H":["e"],"F":["e"],"u.E":"e","F.E":"e"},"eF":{"ah":[]},"ht":{"ah":[]},"t":{"H":["1"]},"eY":{"dD":[]},"bJ":{"H":["1"]},"h_":{"ah":[]},"c7":{"ah":[]},"bz":{"ah":[]},"dO":{"ah":[]},"hl":{"ah":[]},"fn":{"ah":[]},"hT":{"ah":[]},"cq":{"ah":[]},"h5":{"ah":[]},"hA":{"ah":[]},"ff":{"ah":[]},"il":{"aW":[]},"fv":{"ds":[]},"fw":{"ds":[]},"tk":{"t":["l"],"H":["l"]},"ba":{"t":["l"],"H":["l"]},"tU":{"t":["l"],"H":["l"]},"ti":{"t":["l"],"H":["l"]},"tS":{"t":["l"],"H":["l"]},"tj":{"t":["l"],"H":["l"]},"tT":{"t":["l"],"H":["l"]},"t9":{"t":["W"],"H":["W"]},"ta":{"t":["W"],"H":["W"]},"dK":{"P":[]},"f4":{"P":[]},"dU":{"P":[]},"hj":{"P":[]},"hf":{"P":[]},"h4":{"P":[]},"eA":{"P":[]},"ci":{"P":[]},"co":{"P":[]},"bY":{"P":[]},"dw":{"P":[]},"hz":{"P":[]},"dS":{"P":[]},"i_":{"P":[]},"hi":{"P":[]},"dE":{"P":[]},"hL":{"P":[]},"cP":{"P":[]},"dx":{"P":[]},"dv":{"P":[]},"hk":{"P":[]},"hp":{"P":[]},"hU":{"P":[]},"hn":{"P":[]},"hd":{"P":[]},"h9":{"P":[]},"d":{"k":[]},"p":{"k":[]},"a5":{"k":[]},"L":{"k":[]},"j":{"k":[]},"m":{"k":[]},"aN":{"aa":["e","k"],"w":["e","k"],"aa.V":"k","aa.K":"e"},"aO":{"k":[]},"aG":{"k":[]},"bn":{"k":[]},"bm":{"k":[]},"b_":{"k":[]},"a8":{"k":[]},"M":{"y":[]},"bM":{"M":[],"y":[]},"G":{"y":[]},"cL":{"G":[],"y":[]},"aS":{"G":[],"y":[]},"cf":{"G":[],"y":[]},"ag":{"M":[],"y":[]},"aQ":{"M":[],"y":[]},"I":{"M":[],"y":[]},"a0":{"M":[],"y":[]},"af":{"M":[],"y":[]},"cv":{"M":[],"y":[]},"b9":{"M":[],"y":[]},"cs":{"M":[],"y":[]},"dR":{"M":[],"y":[]},"dn":{"M":[],"y":[]},"cJ":{"M":[],"y":[]},"e7":{"y":[]},"hY":{"G":[],"y":[]},"hD":{"y":[]},"hE":{"y":[]},"dk":{"G":[],"y":[]},"dg":{"G":[],"y":[]},"eI":{"M":[],"y":[]},"bR":{"G":[],"y":[]},"dp":{"G":[],"y":[]},"fo":{"G":[],"y":[]},"dm":{"aS":[],"G":[],"y":[]},"cW":{"G":[],"y":[]},"dy":{"G":[],"y":[]},"dr":{"G":[],"y":[]},"dL":{"G":[],"y":[]},"e9":{"G":[],"y":[]},"ez":{"G":[],"y":[]},"fr":{"G":[],"y":[]},"ek":{"G":[],"y":[]},"ea":{"G":[],"y":[]},"ee":{"G":[],"y":[]},"f3":{"G":[],"y":[]},"ey":{"G":[],"y":[]},"f1":{"G":[],"y":[]},"f8":{"G":[],"y":[]},"f7":{"G":[],"y":[]},"ei":{"G":[],"y":[]},"fp":{"G":[],"y":[]},"dj":{"G":[],"y":[]},"dh":{"G":[],"y":[]},"du":{"G":[],"y":[]},"es":{"G":[],"y":[]},"dc":{"G":[],"y":[]},"fc":{"G":[],"y":[]},"fa":{"G":[],"y":[]},"di":{"G":[],"y":[]},"cG":{"G":[],"y":[]},"cF":{"G":[],"y":[]},"ec":{"G":[],"y":[]},"f_":{"G":[],"y":[]},"f6":{"G":[],"y":[]},"f2":{"G":[],"y":[]},"eZ":{"G":[],"y":[]},"eQ":{"G":[],"y":[]},"et":{"G":[],"y":[]},"ed":{"G":[],"y":[]},"dl":{"G":[],"y":[]},"dd":{"M":[],"y":[]},"ce":{"M":[],"y":[]},"em":{"G":[],"y":[]},"cH":{"G":[],"y":[]},"f9":{"G":[],"y":[]},"fb":{"G":[],"y":[]},"eS":{"G":[],"y":[]},"fl":{"G":[],"y":[]},"el":{"G":[],"y":[]},"ew":{"G":[],"y":[]},"ej":{"G":[],"y":[]},"eo":{"G":[],"y":[]},"hM":{"F":["t<k>"],"a1":["t<k>"],"F.E":"t<k>"}}'))
A.ux(v.typeUniverse,JSON.parse('{"H":1,"ev":1,"hW":1,"dW":1,"eg":1,"dG":1,"fu":1,"i8":1,"i7":1,"ii":1,"aT":1,"fH":1,"io":1,"fO":1,"h3":2,"h6":2}'))
var u={c:"Error handler must accept one Object or one Object and a StackTrace as arguments, and return a value of the returned future's type",g:"max must be in range 0 < max \u2264 2^32, was "}
var t=(function rtii(){var s=A.cc
return{bf:s("da"),fr:s("h0"),el:s("a0"),bv:s("aZ"),cv:s("df"),dU:s("bS"),Z:s("bT<e>"),aW:s("cf"),q:s("av"),eM:s("j"),A:s("p"),r:s("k"),W:s("k(w<e,k>)"),gw:s("H<@>"),hd:s("hb"),Q:s("ah"),k:s("M"),fU:s("oI"),ec:s("bH"),b8:s("wA"),du:s("af"),d5:s("ex"),aM:s("B/"),_:s("b8"),de:s("cL"),b1:s("bo"),cK:s("C<aY>"),bd:s("C<aZ>"),aF:s("C<h7>"),d:s("C<av>"),K:s("C<k>"),G:s("C<a5>"),dK:s("C<ha>"),aY:s("C<ch>"),U:s("C<M>"),av:s("C<ds>"),x:s("C<bH>"),dL:s("C<b7<t<w<e,k>>>>"),ae:s("C<cK>"),f8:s("C<a1<k>>"),D:s("C<bo>"),R:s("C<bp>"),F:s("C<t<k>>"),bF:s("C<t<a5>>"),h:s("C<t<M>>"),gy:s("C<t<W>>"),b:s("C<w<e,k>>"),aj:s("C<cm>"),E:s("C<ao>"),gg:s("C<hC>"),bL:s("C<P>"),dG:s("C<br>"),u:s("C<ai>"),I:s("C<aS>"),ei:s("C<cS>"),bA:s("C<bJ<bC>>"),m:s("C<G>"),s:s("C<e>"),aT:s("C<N>"),B:s("C<f>"),a4:s("C<hZ>"),eV:s("C<dX>"),fu:s("C<bM>"),cg:s("C<bE>"),J:s("C<cw>"),g5:s("C<ay>"),f0:s("C<bu>"),bo:s("C<bv>"),f7:s("C<Q>"),n:s("C<W>"),gn:s("C<@>"),t:s("C<l>"),aP:s("aP<@>"),v:s("eE"),eH:s("al"),g:s("be"),aU:s("bf<@>"),aX:s("ar"),eb:s("t<bH>"),b0:s("t<b8>"),gB:s("t<bo>"),c:s("t<w<e,k>>"),be:s("t<ao>"),dy:s("t<e>"),aQ:s("t<bu>"),o:s("t<W>"),j:s("t<@>"),bW:s("t<l>"),fs:s("t<k(w<e,k>)>"),gV:s("ag"),aS:s("aj<e,bt>"),aw:s("aj<e,w<e,@>>"),b_:s("w<e,k>"),a:s("w<e,@>"),g6:s("w<e,l>"),f:s("w<@,@>"),dT:s("w<e,t<e>>"),e:s("h<e,e>"),dh:s("h<e,W>"),cw:s("h<ay,l>"),bq:s("h<a1<k>,k>"),dP:s("bq"),d4:s("cn"),eB:s("bg"),P:s("aE"),C:s("A"),b7:s("dI"),L:s("ao"),h0:s("hB"),d9:s("dJ"),dV:s("br"),eO:s("eW"),gY:s("ai"),V:s("B"),gT:s("wG"),bQ:s("+()"),cz:s("eY"),fM:s("dP"),bJ:s("f0<e>"),gZ:s("cp"),Y:s("bC"),fi:s("hO"),eu:s("bJ<k>"),gc:s("bJ<fh<e>>"),cq:s("bJ<e>"),l:s("aW"),cf:s("G"),da:s("fh<t<k>>"),N:s("e"),eT:s("c6"),h2:s("bt"),dn:s("fj"),f6:s("cV"),dm:s("ac"),ch:s("dV"),eK:s("c7"),p:s("ba"),cE:s("hS"),ak:s("cu"),dC:s("fm<l>"),w:s("I"),af:s("fs<t<k>>"),cY:s("bE"),aI:s("i5"),eI:s("ad<@>"),fj:s("bv"),fC:s("cx<k>"),y:s("Q"),i:s("W"),z:s("@"),bI:s("@(A)"),ag:s("@(A,aW)"),S:s("l"),g1:s("k?"),ev:s("k(w<e,k>)?"),O:s("M?"),bG:s("b7<aE>?"),an:s("al?"),eg:s("t<l>?"),fY:s("w<e,k>?"),X:s("A?"),M:s("cS?"),T:s("e?"),fQ:s("Q?"),cD:s("W?"),h6:s("l?"),e6:s("r9?"),di:s("r9"),H:s("~")}})();(function constants(){var s=hunkHelpers.makeConstList
B.cB=J.hm.prototype
B.b=J.C.prototype
B.cC=J.eC.prototype
B.c=J.eD.prototype
B.h=J.cM.prototype
B.a=J.ck.prototype
B.cD=J.be.prototype
B.cE=J.ar.prototype
B.r=A.eJ.prototype
B.ab=A.eK.prototype
B.E=A.eL.prototype
B.j=A.eO.prototype
B.ba=J.hI.prototype
B.b1=J.cu.prototype
B.b2=new A.db(0,"add")
B.b3=new A.db(1,"drop")
B.b4=new A.db(2,"renameColumn")
B.b5=new A.db(3,"alterColumnType")
B.co=new A.ep(A.cc("ep<0&>"))
B.dn=new A.j4()
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

B.o=new A.lN()
B.cv=new A.hA()
B.V=new A.mM()
B.a5=new A.nb()
B.x=new A.nc()
B.cw=new A.nF()
B.m=new A.ih()
B.aw=new A.av(0,"integer")
B.L=new A.av(1,"double")
B.t=new A.av(2,"text")
B.W=new A.av(3,"vector")
B.M=new A.av(4,"json")
B.a6=new A.av(5,"boolean")
B.a7=new A.av(6,"uuid")
B.a8=new A.av(7,"datetime")
B.a9=new A.av(8,"blob")
B.aa=new A.av(9,"decimal")
B.f=new A.bW(0)
B.cx=new A.cI(0)
B.cy=new A.cI(1)
B.b8=new A.cI(2)
B.cz=new A.cI(3)
B.cA=new A.cI(4)
B.cF=new A.lO(null)
B.cG=new A.lP(null)
B.cH=s([B.aw,B.L,B.t,B.W,B.M,B.a6,B.a7,B.a8,B.a9,B.aa],t.d)
B.cI=s([],t.K)
B.cJ=s([],t.U)
B.b9=s([],t.R)
B.cN={analyze:0,explain:1,select:2,from:3,where:4,join:5,on:6,limit:7,order:8,by:9,asc:10,desc:11,create:12,table:13,insert:14,into:15,values:16,as:17,commit:18,rollback:19,relationship:20,index:21,show:22,tables:23,indexes:24,to:25,with:26,in:27,generate:28,group:29,like:30,between:31,and:32,or:33,having:34,primary:35,key:36,unique:37,references:38,delete:39,cascade:40,alter:41,add:42,drop:43,column:44,check:45,default:46,declare:47,begin:48,end:49,if:50,then:51,else:52,elsif:53,while:54,loop:55,int:56,integer:57,bigint:58,smallint:59,double:60,real:61,float:62,decimal:63,numeric:64,text:65,varchar:66,char:67,string:68,vector:69,json:70,bool:71,boolean:72,uuid:73,guid:74,datetime:75,timestamp:76,date:77,blob:78,bytea:79,bytes:80,true:81,false:82,cast:83,pragma:84,describe:85,columns:86,schemas:87,truncate:88,exists:89,ilike:90,not:91,null:92,policy:93,using:94,conflict:95,do:96,nothing:97,replace:98,macro:99,stream:100,emit:101,procedure:102,function:103,returns:104,return:105,call:106,union:107,all:108,over:109,partition:110,intersect:111,except:112,distinct:113,offset:114,savepoint:115,release:116,cursor:117,for:118,open:119,fetch:120,close:121,trigger:122,before:123,after:124,each:125,row:126,exception:127,when:128,fts:129,match:130,recursive:131,rollup:132,cube:133,grouping:134,sets:135,foreign:136,server:137,options:138,checkpoint:139,vacuum:140,full:141,of:142,system:143,time:144,transaction:145,range:146,masked:147}
B.ay=new A.f(100,"analyze")
B.bb=new A.f(0,"explain")
B.v=new A.f(1,"select")
B.B=new A.f(2,"from")
B.G=new A.f(3,"where")
B.C=new A.f(4,"join")
B.z=new A.f(5,"on")
B.al=new A.f(6,"limit")
B.a4=new A.f(7,"orderBy")
B.T=new A.f(8,"by")
B.aX=new A.f(9,"asc")
B.ax=new A.f(10,"desc")
B.bf=new A.f(11,"create")
B.N=new A.f(12,"table")
B.aG=new A.f(13,"insert")
B.aI=new A.f(14,"into")
B.af=new A.f(15,"valuesKeyword")
B.y=new A.f(16,"as")
B.bS=new A.f(17,"commit")
B.bT=new A.f(18,"rollback")
B.aQ=new A.f(19,"relationship")
B.aR=new A.f(20,"indexKeyword")
B.bW=new A.f(28,"showKeyword")
B.aS=new A.f(29,"tablesKeyword")
B.bX=new A.f(30,"indexesKeyword")
B.O=new A.f(21,"to")
B.A=new A.f(22,"withKeyword")
B.ah=new A.f(23,"inKeyword")
B.P=new A.f(24,"generate")
B.ai=new A.f(25,"groupKeyword")
B.bU=new A.f(26,"likeKeyword")
B.bY=new A.f(31,"betweenKeyword")
B.aT=new A.f(32,"andKeyword")
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
B.aU=new A.f(43,"dropKeyword")
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
B.aV=new A.f(55,"whileKeyword")
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
B.aM=new A.f(156,"columnsKeyword")
B.aN=new A.f(157,"schemasKeyword")
B.bK=new A.f(158,"truncateKeyword")
B.aO=new A.f(159,"existsKeyword")
B.bV=new A.f(27,"ilikeKeyword")
B.aL=new A.f(151,"notKeyword")
B.ag=new A.f(152,"nullKeyword")
B.cn=new A.f(98,"policyKeyword")
B.b_=new A.f(99,"usingKeyword")
B.bL=new A.f(161,"conflictKeyword")
B.bM=new A.f(162,"doKeyword")
B.bN=new A.f(163,"nothingKeyword")
B.aP=new A.f(164,"replaceKeyword")
B.bP=new A.f(166,"macroKeyword")
B.bQ=new A.f(167,"streamKeyword")
B.bR=new A.f(168,"emitKeyword")
B.bd=new A.f(107,"procedureKeyword")
B.az=new A.f(108,"functionKeyword")
B.be=new A.f(109,"returnsKeyword")
B.aA=new A.f(110,"returnKeyword")
B.aB=new A.f(111,"callKeyword")
B.aC=new A.f(112,"union")
B.bc=new A.f(104,"all")
B.bg=new A.f(113,"over")
B.ac=new A.f(114,"partition")
B.aD=new A.f(115,"intersect")
B.aE=new A.f(116,"except")
B.bh=new A.f(117,"distinct")
B.bi=new A.f(118,"offset")
B.bj=new A.f(119,"savepointKeyword")
B.bk=new A.f(120,"releaseKeyword")
B.aF=new A.f(121,"cursorKeyword")
B.X=new A.f(122,"forKeyword")
B.bl=new A.f(123,"openKeyword")
B.bm=new A.f(124,"fetchKeyword")
B.bn=new A.f(125,"closeKeyword")
B.bo=new A.f(126,"triggerKeyword")
B.bp=new A.f(127,"beforeKeyword")
B.bq=new A.f(128,"afterKeyword")
B.br=new A.f(129,"eachKeyword")
B.bs=new A.f(130,"rowKeyword")
B.aH=new A.f(131,"exceptionKeyword")
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
B.aJ=new A.f(146,"systemKeyword")
B.aK=new A.f(147,"timeKeyword")
B.bE=new A.f(148,"transactionKeyword")
B.bF=new A.f(149,"rangeKeyword")
B.bG=new A.f(150,"maskedKeyword")
B.cK=new A.eh(B.cN,[B.ay,B.bb,B.v,B.B,B.G,B.C,B.z,B.al,B.a4,B.T,B.aX,B.ax,B.bf,B.N,B.aG,B.aI,B.af,B.y,B.bS,B.bT,B.aQ,B.aR,B.bW,B.aS,B.bX,B.O,B.A,B.ah,B.P,B.ai,B.bU,B.bY,B.aT,B.bZ,B.c_,B.c0,B.c1,B.c2,B.c3,B.Y,B.c4,B.c5,B.c6,B.aU,B.aj,B.c7,B.c8,B.Q,B.w,B.p,B.R,B.Z,B.a_,B.ak,B.aV,B.a0,B.H,B.H,B.H,B.H,B.S,B.S,B.S,B.aq,B.aq,B.I,B.I,B.I,B.I,B.am,B.an,B.ao,B.ao,B.ap,B.ap,B.a1,B.a1,B.a1,B.a2,B.a2,B.a2,B.c9,B.ca,B.bH,B.bI,B.bJ,B.aM,B.aN,B.bK,B.aO,B.bV,B.aL,B.ag,B.cn,B.b_,B.bL,B.bM,B.bN,B.aP,B.bP,B.bQ,B.bR,B.bd,B.az,B.be,B.aA,B.aB,B.aC,B.bc,B.bg,B.ac,B.aD,B.aE,B.bh,B.bi,B.bj,B.bk,B.aF,B.X,B.bl,B.bm,B.bn,B.bo,B.bp,B.bq,B.br,B.bs,B.aH,B.ad,B.cU,B.bt,B.bu,B.bv,B.bw,B.bx,B.by,B.bz,B.bA,B.bB,B.cV,B.bC,B.bD,B.ae,B.aJ,B.aK,B.bE,B.bF,B.bG],A.cc("eh<e,f>"))
B.cM={a:0,about:1,above:2,after:3,again:4,against:5,all:6,am:7,an:8,and:9,any:10,are:11,"aren't":12,as:13,at:14,be:15,because:16,been:17,before:18,being:19,below:20,between:21,both:22,but:23,by:24,"can't":25,cannot:26,could:27,"couldn't":28,did:29,"didn't":30,do:31,does:32,"doesn't":33,doing:34,"don't":35,down:36,during:37,each:38,few:39,for:40,from:41,further:42,had:43,"hadn't":44,has:45,"hasn't":46,have:47,"haven't":48,having:49,he:50,"he'd":51,"he'll":52,"he's":53,her:54,here:55,"here's":56,hers:57,herself:58,him:59,himself:60,his:61,how:62,"how's":63,i:64,"i'd":65,"i'll":66,"i'm":67,"i've":68,if:69,in:70,into:71,is:72,"isn't":73,it:74,"it's":75,its:76,itself:77,"let's":78,me:79,more:80,most:81,"mustn't":82,my:83,myself:84,no:85,nor:86,not:87,of:88,off:89,on:90,once:91,only:92,or:93,other:94,ought:95,our:96,ours:97,ourselves:98,out:99,over:100,own:101,same:102,"shan't":103,she:104,"she'd":105,"she'll":106,"she's":107,should:108,"shouldn't":109,so:110,some:111,such:112,than:113,that:114,"that's":115,the:116,their:117,theirs:118,them:119,themselves:120,then:121,there:122,"there's":123,these:124,they:125,"they'd":126,"they'll":127,"they're":128,"they've":129,this:130,those:131,through:132,to:133,too:134,under:135,until:136,up:137,very:138,was:139,"wasn't":140,we:141,"we'd":142,"we'll":143,"we're":144,"we've":145,were:146,"weren't":147,what:148,"what's":149,when:150,"when's":151,where:152,"where's":153,which:154,while:155,who:156,"who's":157,whom:158,why:159,"why's":160,with:161,"won't":162,would:163,"wouldn't":164,you:165,"you'd":166,"you'll":167,"you're":168,"you've":169,your:170,yours:171,yourself:172,yourselves:173}
B.cQ=new A.bT(B.cM,174,t.Z)
B.cO={}
B.u=new A.bT(B.cO,0,A.cc("bT<l>"))
B.cP={int:0,integer:1,bigint:2,smallint:3,double:4,real:5,float:6,decimal:7,numeric:8,text:9,varchar:10,char:11,string:12,vector:13,json:14}
B.cR=new A.bT(B.cP,15,t.Z)
B.cL={update:0,select:1,insert:2,delete:3,create:4,show:5,grant:6,revoke:7,explain:8,analyze:9,use:10}
B.cS=new A.bT(B.cL,11,t.Z)
B.F=new A.hR("sessionTxContext")
B.cT=new A.f(105,"setKeyword")
B.bO=new A.f(165,"tilde")
B.d=new A.f(67,"identifier")
B.a3=new A.f(68,"numberLiteral")
B.q=new A.f(69,"stringLiteral")
B.cb=new A.f(72,"plus")
B.ar=new A.f(73,"minus")
B.as=new A.f(74,"asterisk")
B.cc=new A.f(75,"slash")
B.D=new A.f(76,"equals")
B.aW=new A.f(77,"notEquals")
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
B.aY=new A.f(91,"rBracket")
B.n=new A.f(92,"comma")
B.e=new A.f(93,"semicolon")
B.J=new A.f(94,"dot")
B.k=new A.f(95,"eof")
B.K=new A.f(96,"invalid")
B.aZ=new A.f(97,"placeholder")
B.au=new A.dV(0,"active")
B.U=new A.dV(1,"committed")
B.b0=new A.dV(2,"aborted")
B.cW=A.bF("wq")
B.cX=A.bF("wr")
B.cY=A.bF("t9")
B.cZ=A.bF("ta")
B.d_=A.bF("ti")
B.d0=A.bF("tj")
B.d1=A.bF("tk")
B.d2=A.bF("A")
B.d3=A.bF("tS")
B.d4=A.bF("tT")
B.d5=A.bF("tU")
B.d6=A.bF("ba")
B.d7=new A.hX(!1)
B.d8=new A.hX(!0)
B.av=new A.il("")
B.d9=new A.aT(B.m,A.vO())
B.da=new A.aT(B.m,A.vK())
B.db=new A.aT(B.m,A.vS())
B.dc=new A.aT(B.m,A.vL())
B.dd=new A.aT(B.m,A.vM())
B.de=new A.aT(B.m,A.vN())
B.df=new A.aT(B.m,A.vP())
B.dg=new A.aT(B.m,A.vR())
B.dh=new A.aT(B.m,A.vT())
B.di=new A.aT(B.m,A.vU())
B.dj=new A.aT(B.m,A.vV())
B.dk=new A.aT(B.m,A.vW())
B.dl=new A.aT(B.m,A.vQ())
B.dm=new A.iq(null,null,null,null,null,null,null,null,null,null,null,null,null)})();(function staticFields(){$.nG=null
$.d5=A.a([],A.cc("C<A>"))
$.pk=null
$.qc=null
$.ml=0
$.bs=A.vi()
$.pK=null
$.pJ=null
$.r7=null
$.qZ=null
$.re=null
$.od=null
$.ol=null
$.ps=null
$.nM=A.a([],A.cc("C<t<A>?>"))
$.e0=null
$.fR=null
$.fS=null
$.pj=!1
$.V=B.m
$.nN=null
$.wW=A.o(t.S,A.cc("wV"))
$.cD=A.a([99,124,119,123,242,107,111,197,48,1,103,43,254,215,171,118,202,130,201,125,250,89,71,240,173,212,162,175,156,164,114,192,183,253,147,38,54,63,247,204,52,165,229,241,113,216,49,21,4,199,35,195,24,150,5,154,7,18,128,226,235,39,178,117,9,131,44,26,27,110,90,160,82,59,214,179,41,227,47,132,83,209,0,237,32,252,177,91,106,203,190,57,74,76,88,207,208,239,170,251,67,77,51,133,69,249,2,127,80,60,159,168,81,163,64,143,146,157,56,245,188,182,218,33,16,255,243,210,205,12,19,236,95,151,68,23,196,167,126,61,100,93,25,115,96,129,79,220,34,42,144,136,70,238,184,20,222,94,11,219,224,50,58,10,73,6,36,92,194,211,172,98,145,149,228,121,231,200,55,109,141,213,78,169,108,86,244,234,101,122,174,8,186,120,37,46,28,166,180,198,232,221,116,31,75,189,139,138,112,62,181,102,72,3,246,14,97,53,87,185,134,193,29,158,225,248,152,17,105,217,142,148,155,30,135,233,206,85,40,223,140,161,137,13,191,230,66,104,65,153,45,15,176,84,187,22],t.t)
$.eB=A.o(t.N,A.cc("t<y>"))
$.pX=0
$.cN=null
$.pS=A.a([],A.cc("C<oI>"))
$.oK=null
$.pR=""
$.oJ=!1
$.cU=A.a([],t.b)
$.pd=A.qu()})();(function lazyInitializers(){var s=hunkHelpers.lazyFinal,r=hunkHelpers.lazy
s($,"wt","rh",()=>A.r6("_$dart_dartClosure"))
s($,"ws","os",()=>A.r6("_$dart_dartClosure_dartJSInterop"))
s($,"wU","ou",()=>A.lW(0))
s($,"x3","rD",()=>A.a([new J.hq()],A.cc("C<f5>")))
s($,"wJ","rn",()=>A.c8(A.n7({
toString:function(){return"$receiver$"}})))
s($,"wK","ro",()=>A.c8(A.n7({$method$:null,
toString:function(){return"$receiver$"}})))
s($,"wL","rp",()=>A.c8(A.n7(null)))
s($,"wM","rq",()=>A.c8(function(){var $argumentsExpr$="$arguments$"
try{null.$method$($argumentsExpr$)}catch(q){return q.message}}()))
s($,"wP","rt",()=>A.c8(A.n7(void 0)))
s($,"wQ","ru",()=>A.c8(function(){var $argumentsExpr$="$arguments$"
try{(void 0).$method$($argumentsExpr$)}catch(q){return q.message}}()))
s($,"wO","rs",()=>A.c8(A.qr(null)))
s($,"wN","rr",()=>A.c8(function(){try{null.$method$}catch(q){return q.message}}()))
s($,"wS","rw",()=>A.c8(A.qr(void 0)))
s($,"wR","rv",()=>A.c8(function(){try{(void 0).$method$}catch(q){return q.message}}()))
s($,"wT","py",()=>A.tV())
s($,"wX","rx",()=>{var q=t.z
return A.pV(q,q)})
s($,"x_","rA",()=>A.lW(4096))
s($,"wY","ry",()=>new A.nX().$0())
s($,"wZ","rz",()=>new A.nW().$0())
s($,"wu","ri",()=>A.aI("^([+-]?\\d{4,6})-?(\\d\\d)-?(\\d\\d)(?:[ T](\\d\\d)(?::?(\\d\\d)(?::?(\\d\\d)(?:[.,](\\d+))?)?)?( ?[zZ]| ?([-+])(\\d\\d)(?::?(\\d\\d))?)?)?$",!0))
s($,"x0","ov",()=>A.rb(B.d2))
s($,"wH","cC",()=>{A.tB()
return $.ml})
s($,"wy","rj",()=>A.aI("^(?:\\\\\\\\|[a-zA-Z]:[/\\\\])",!0))
s($,"wz","rk",()=>$.fW()?A.aI("[^/\\\\][/\\\\]+[^/\\\\]",!0):A.aI("[^/]/+[^/]",!0))
s($,"x1","rB",()=>new A.A())
s($,"wD","rl",()=>A.un())
s($,"wF","ot",()=>A.up())
s($,"wE","rm",()=>A.uo())
r($,"wC","fW",()=>{$.rm()
return!1})
s($,"x2","rC",()=>Symbol("jsBoxedDartObjectProperty"))
s($,"x4","pz",()=>A.lW(1048576))
s($,"wx","T",()=>A.oF(0))
s($,"ww","U",()=>A.oF(1))
s($,"wv","px",()=>{var q,p=J.dz(1101,t.A)
for(q=0;q<1101;++q)p[q]=A.oF(q-100)
return p})
s($,"x5","ow",()=>A.lW(65536))
s($,"x6","rE",()=>A.aq($.ow(),0,null))})();(function nativeSupport(){!function(){var s=function(a){var m={}
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
hunkHelpers.setOrUpdateInterceptorsByTag({ArrayBuffer:A.dF,SharedArrayBuffer:A.dF,ArrayBufferView:A.eM,DataView:A.eJ,Float32Array:A.hu,Float64Array:A.eK,Int16Array:A.hv,Int32Array:A.eL,Int8Array:A.hw,Uint16Array:A.hx,Uint32Array:A.hy,Uint8ClampedArray:A.eN,CanvasPixelArray:A.eN,Uint8Array:A.eO})
hunkHelpers.setOrUpdateLeafTags({ArrayBuffer:true,SharedArrayBuffer:true,ArrayBufferView:false,DataView:true,Float32Array:true,Float64Array:true,Int16Array:true,Int32Array:true,Int8Array:true,Uint16Array:true,Uint32Array:true,Uint8ClampedArray:true,CanvasPixelArray:true,Uint8Array:false})
A.dG.$nativeSuperclassTag="ArrayBufferView"
A.fC.$nativeSuperclassTag="ArrayBufferView"
A.fD.$nativeSuperclassTag="ArrayBufferView"
A.cn.$nativeSuperclassTag="ArrayBufferView"
A.fE.$nativeSuperclassTag="ArrayBufferView"
A.fF.$nativeSuperclassTag="ArrayBufferView"
A.bg.$nativeSuperclassTag="ArrayBufferView"})()
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
var s=A.om
if(typeof dartMainRunner==="function"){dartMainRunner(s,[])}else{s([])}})})()
//# sourceMappingURL=ultsql_engine.js.map
