/**
 * Post-build patch: move the Evidence splash screen outside the SvelteKit
 * mount container so it survives kit.start() and ensure it is visible.
 *
 * In the built HTML the structure is:
 *   <body>
 *     <div>                           ← SvelteKit mount container
 *       <!-- SvelteKit Hydrated Content -->
 *       <script>…kit.start(app, element)…</script>
 *       <!-- SplashScreen -->
 *       <div id="__evidence_project_splash" style="visibility: hidden">…</div>
 *     </div>
 *   </body>
 *
 * kit.start() replaces the container's children, destroying the splash before
 * the browser paints it. This script moves the splash to be a direct child of
 * <body> and sets visibility to visible.
 */

import { readdir, readFile, writeFile } from 'node:fs/promises';
import { join } from 'node:path';

const BUILD_DIR = new URL('../build', import.meta.url).pathname;

const SPLASH_RE =
	/(\s*)(<!-- SplashScreen -->[\s\S]*?<div\s[^>]*id="__evidence_project_splash"[\s\S]*?<\/div>)/g;

async function findHtmlFiles(dir) {
	const entries = await readdir(dir, { withFileTypes: true, recursive: true });
	return entries
		.filter((e) => e.isFile() && e.name === 'index.html')
		.map((e) => join(e.parentPath ?? e.path, e.name));
}

async function patchFile(filePath) {
	let html = await readFile(filePath, 'utf-8');
	const original = html;

	// 1. Extract the splash block and remove it from its current location
	let splashBlock = '';
	html = html.replace(SPLASH_RE, (_match, _indent, block) => {
		splashBlock = block;
		return '';
	});

	if (!splashBlock) return false;

	// 2. Ensure visibility: visible
	splashBlock = splashBlock.replace(
		/style="visibility:\s*hidden"/,
		'style="visibility: visible"'
	);

	// 3. Insert the splash as a direct child of <body>, before the mount container
	html = html.replace(/(<body[^>]*>\s*)/, `$1\n\t\t${splashBlock.trim()}\n`);

	if (html === original) return false;

	await writeFile(filePath, html, 'utf-8');
	return true;
}

const files = await findHtmlFiles(BUILD_DIR);
let patched = 0;

for (const f of files) {
	if (await patchFile(f)) patched++;
}

console.log(`patch-splash: patched ${patched}/${files.length} HTML files`);
