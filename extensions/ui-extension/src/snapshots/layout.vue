<template>
	<div class="layout-split">
		<div class="left-pane">
			<v-list :items="items" item-key="id" @click:row="selectItem" />
		</div>
		<div class="right-pane">
			<v-detail v-if="selected" :item="selected" />
			<p v-else>Select an item to see details.</p>
		</div>
	</div>
</template>

<script setup lang="ts">
import { ref } from 'vue';

const props = defineProps({
	items: Array,
});

const selected = ref(null);

function selectItem(item: null) {
	selected.value = item;
}
</script>

<style scoped>
.layout-split {
	display: flex;
	height: 100%;
}

.left-pane {
	width: 40%;
	overflow-y: auto;
	border-right: 1px solid #ddd;
	padding: 1rem;
}

.right-pane {
	width: 60%;
	padding: 1rem;
	overflow-y: auto;
}
</style>