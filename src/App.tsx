import { onMount } from "solid-js";

function App() {
	onMount(() => {
		window.location.href = "http://192.168.18.182:5173";
	});

	return null; // 直接返回 null，不显示任何内容
}

export default App;

