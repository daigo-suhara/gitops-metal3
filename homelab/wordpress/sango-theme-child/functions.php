<?php
/**
 * SANGO Child - Warm Editorial
 * Loads Google Fonts (Playfair Display + Inter + Noto Serif/Sans JP + JetBrains Mono),
 * child stylesheet on top of parent, and Prism.js for syntax highlighting.
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

add_action( 'wp_enqueue_scripts', 'we_enqueue_child_assets', 20 );
function we_enqueue_child_assets() {
	// Fonts (Playfair Display, Inter, Noto Serif JP, Noto Sans JP, JetBrains Mono)
	wp_enqueue_style(
		'we-google-fonts',
		'https://fonts.googleapis.com/css2?family=Playfair+Display:wght@400;700&family=Inter:wght@400;500;600;700&family=Noto+Serif+JP:wght@400;700&family=Noto+Sans+JP:wght@400;500;700&family=JetBrains+Mono:wght@400;500&display=swap',
		array(),
		null
	);

	// Child stylesheet - depends on parent's sng-stylesheet + sng-option so it wins the cascade
	wp_enqueue_style(
		'child-style',
		get_stylesheet_directory_uri() . '/style.css',
		array( 'sng-stylesheet', 'sng-option', 'we-google-fonts' ),
		wp_get_theme()->get( 'Version' )
	);

	// Prism.js core + autoloader + line numbers (CDN)
	wp_enqueue_style(
		'prism-line-numbers-css',
		'https://cdn.jsdelivr.net/npm/prismjs@1.29.0/plugins/line-numbers/prism-line-numbers.min.css',
		array( 'child-style' ),
		'1.29.0'
	);
	wp_enqueue_script(
		'prism-core',
		'https://cdn.jsdelivr.net/npm/prismjs@1.29.0/components/prism-core.min.js',
		array(),
		'1.29.0',
		true
	);
	wp_enqueue_script(
		'prism-autoloader',
		'https://cdn.jsdelivr.net/npm/prismjs@1.29.0/plugins/autoloader/prism-autoloader.min.js',
		array( 'prism-core' ),
		'1.29.0',
		true
	);
	wp_enqueue_script(
		'prism-line-numbers',
		'https://cdn.jsdelivr.net/npm/prismjs@1.29.0/plugins/line-numbers/prism-line-numbers.min.js',
		array( 'prism-core' ),
		'1.29.0',
		true
	);
}

// Auto-add `line-numbers` class and a fallback language class to bare <pre>.
add_filter( 'the_content', 'we_pre_add_line_numbers', 20 );
function we_pre_add_line_numbers( $content ) {
	return preg_replace(
		'/<pre(?![^>]*class=)/',
		'<pre class="line-numbers language-none"',
		$content
	);
}
