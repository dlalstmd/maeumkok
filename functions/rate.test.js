// node functions/rate.test.js
process.env.GCLOUD_PROJECT = "test";
const assert = require("assert");
const {rateDecision} = require("./index.js");
let s = null; const t = 1000000;
let d = rateDecision(s, "happy", t); assert(d.allowed && d.push); s = d.next;
d = rateDecision(s, "happy", t + 3000); assert(d.allowed && !d.push); s = d.next;
d = rateDecision(s, "sad", t + 4000); assert(d.push); s = d.next;
d = rateDecision(s, "happy", t + 11000); assert(d.push); s = d.next;
for (let i = 0; i < 26; i++) { d = rateDecision(s, "x" + i, t + 12000 + i); s = d.next; }
assert(d.allowed); d = rateDecision(s, "y", t + 20000); assert(!d.allowed); s = d.next;
d = rateDecision(s, "y", t + 61000); assert(d.allowed);
console.log("rate tests ok");
