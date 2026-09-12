import assert from "node:assert/strict";
import test from "node:test";
import { cleanResult, decodedImageInfo } from "../src/index.js";

test("accepts a JPEG payload", () => {
  const encoded = Buffer.from([0xff, 0xd8, 0xff, 0x00]).toString("base64");
  assert.equal(decodedImageInfo(encoded).mime, "image/jpeg");
});

test("rejects a non-image payload", () => {
  assert.equal(decodedImageInfo(Buffer.from("hello").toString("base64")), null);
});

test("normalizes model output", () => {
  assert.deepEqual(cleanResult({ medicines: [{ name: " 药品 ", source_text: " 原文 " }], warnings: [] }), {
    medicines: [{ name: "药品", specification: null, dose: null, frequency: null, method: null, source_text: "原文" }], warnings: [],
  });
});

test("requires source text", () => {
  assert.throws(() => cleanResult({ medicines: [{ name: "药品" }], warnings: [] }));
});
