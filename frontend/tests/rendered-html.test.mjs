import assert from "node:assert/strict";
import { access } from "node:fs/promises";
import test from "node:test";

async function render() {
  const workerUrl = new URL("../dist/server/index.js", import.meta.url);
  workerUrl.searchParams.set("test", `${process.pid}-${Date.now()}`);
  const { default: worker } = await import(workerUrl.href);

  return worker.fetch(
    new Request("https://notium.shona.lat/", {
      headers: { accept: "text/html", host: "notium.shona.lat" },
    }),
    {
      ASSETS: { fetch: async () => new Response("Not found", { status: 404 }) },
    },
    { waitUntil() {}, passThroughOnException() {} },
  );
}

test("renderiza la landing completa de Notium", async () => {
  const response = await render();
  assert.equal(response.status, 200);
  assert.match(response.headers.get("content-type") ?? "", /^text\/html\b/i);

  const html = await response.text();
  assert.match(html, /<html lang="es">/i);
  assert.match(html, /<title>Notium — Notas offline-first para Android<\/title>/i);
  assert.match(html, /Tus notas no/);
  assert.match(html, /Local primero/);
  assert.match(html, /Ciclo de sincronización/);
  assert.match(html, /Jhonatan Castro/);
  assert.match(html, /Probar en l(?:í|&#xED;)nea/);
  assert.match(html, /appetize\.io\/app\/b_twsuanr6f4tzug6lfgqmo46wqe/);
  assert.match(html, /releases\/latest\/download\/notium-v1\.0\.0\.apk/);
  assert.match(html, /og\.png/);
  assert.doesNotMatch(html, /codex-preview|SkeletonPreview|Your site is taking shape/);
});

test("elimina por completo la vista temporal del starter", async () => {
  await assert.rejects(
    access(new URL("../app/_sites-preview/SkeletonPreview.tsx", import.meta.url)),
  );
  await assert.rejects(
    access(new URL("../app/_sites-preview/preview.css", import.meta.url)),
  );
});
