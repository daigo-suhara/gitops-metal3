<?php
/**
 * SANGO Tech Child Theme
 * Zenn-inspired sepia-light styling with Catppuccin Mocha code blocks.
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

add_action( 'wp_enqueue_scripts', function () {
	wp_enqueue_style(
		'sango-parent-style',
		get_template_directory_uri() . '/style.css',
		[],
		wp_get_theme( 'sango-theme' )->get( 'Version' )
	);

	wp_enqueue_style(
		'sango-tech-style',
		get_stylesheet_uri(),
		[ 'sango-parent-style' ],
		wp_get_theme()->get( 'Version' )
	);

	wp_enqueue_style(
		'prism-css',
		'https://cdn.jsdelivr.net/npm/prismjs@1.29.0/themes/prism-tomorrow.min.css',
		[],
		'1.29.0'
	);
	wp_enqueue_style(
		'prism-line-numbers-css',
		'https://cdn.jsdelivr.net/npm/prismjs@1.29.0/plugins/line-numbers/prism-line-numbers.min.css',
		[ 'prism-css' ],
		'1.29.0'
	);

	wp_enqueue_script(
		'prism-core',
		'https://cdn.jsdelivr.net/npm/prismjs@1.29.0/components/prism-core.min.js',
		[],
		'1.29.0',
		true
	);
	wp_enqueue_script(
		'prism-autoloader',
		'https://cdn.jsdelivr.net/npm/prismjs@1.29.0/plugins/autoloader/prism-autoloader.min.js',
		[ 'prism-core' ],
		'1.29.0',
		true
	);
	wp_enqueue_script(
		'prism-line-numbers',
		'https://cdn.jsdelivr.net/npm/prismjs@1.29.0/plugins/line-numbers/prism-line-numbers.min.js',
		[ 'prism-core' ],
		'1.29.0',
		true
	);
}, 20 );

// Ensure every <pre> gets line-numbers + a language class so Prism activates cleanly.
add_filter( 'the_content', function ( $content ) {
	return preg_replace(
		'/<pre(?![^>]*class=)/',
		'<pre class="line-numbers language-none"',
		$content
	);
}, 20 );
