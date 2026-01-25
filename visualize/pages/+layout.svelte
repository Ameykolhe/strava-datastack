<script>
	import '@evidence-dev/tailwind/fonts.css';
	import '../app.css';
	import CustomLayout from '../components/CustomLayout.svelte';
	export let data;
</script>

<CustomLayout {data}>
	<slot slot="content" />
</CustomLayout>
