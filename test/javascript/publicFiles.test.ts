import { expect, test } from "bun:test";
import { existsSync, readFileSync, statSync } from "node:fs";
import { join } from "node:path";

// Static files served straight from public/, with no asset pipeline behind them.
const publicDir = join(import.meta.dir, "../../public");
const read = (name: string) => readFileSync(join(publicDir, name));

const errorPages = ["404.html", "422.html", "500.html"].filter((name) =>
  existsSync(join(publicDir, name))
);

test("the static 500 page exists", () => {
  expect(errorPages).toContain("500.html");
});

test.each(errorPages)(
  "%s loads its images without the asset pipeline",
  (name) => {
    const html = read(name).toString();
    // /assets/* filenames are digested in production, so a bare path 404s
    expect(html).not.toContain("/assets/");

    const sources = [...html.matchAll(/<img[^>]+src="([^"]+)"/g)].map(
      ([, src]) => src
    );
    for (const src of sources) {
      if (src.startsWith("data:")) {
        continue;
      }
      expect(src.startsWith("/")).toBe(true);
      expect(existsSync(join(publicDir, src))).toBe(true);
    }
  }
);

test.each(errorPages)("%s points people at the bakery's inbox", (name) => {
  const html = read(name).toString();
  expect(html).not.toContain("motzi@motzi.org");
  const addresses = [...html.matchAll(/mailto:([^"'?]+)/g)].map(
    ([, address]) => address
  );
  for (const address of addresses) {
    expect(address).toBe("info@motzibread.com");
  }
});

test("the 500 page shows the logo and the contact address", () => {
  const html = read("500.html").toString();
  expect(html).toMatch(
    /<img[^>]+src="data:image\/png;base64,[^"]+"[^>]+alt="Motzi"/
  );
  expect(html).toContain("mailto:info@motzibread.com");
});

const PNG_SIGNATURE = [0x89, 0x50, 0x4e, 0x47];
const ICO_SIGNATURE = [0x00, 0x00, 0x01, 0x00];

test.each([
  ["favicon.ico", ICO_SIGNATURE],
  ["apple-touch-icon.png", PNG_SIGNATURE],
  ["apple-touch-icon-precomposed.png", PNG_SIGNATURE],
])("%s is a real image, not an empty file", (name, signature) => {
  expect(statSync(join(publicDir, name)).size).toBeGreaterThan(100);
  expect([...read(name).subarray(0, 4)]).toStrictEqual(signature);
});

test("apple touch icons are 180px squares", () => {
  for (const name of [
    "apple-touch-icon.png",
    "apple-touch-icon-precomposed.png",
  ]) {
    const png = read(name);
    // IHDR: width and height are big-endian uint32s at bytes 16 and 20
    expect(png.readUInt32BE(16)).toBe(180);
    expect(png.readUInt32BE(20)).toBe(180);
  }
});
