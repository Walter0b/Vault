<template>
	<div class="travelers-interface">
		<!-- Left sidebar: table of travelers -->
		<div class="sidebar">
			<table>
				<thead>
					<tr>
						<th>Traveler</th>
					</tr>
				</thead>
				<tbody>
					<tr v-for="traveler in travelers" :key="traveler.id" @click="selectTraveler(traveler)"
						:class="{ active: traveler.id === selectedTraveler?.id }">
						<td>{{ traveler.name }}</td>
					</tr>
				</tbody>
			</table>
		</div>

		<!-- Right panel: preview details only appear when an item is clicked -->
		<div class="preview" v-if="selectedTraveler">
			<h2>{{ selectedTraveler.name }}</h2>
			<p><strong>Income:</strong> {{ selectedTraveler.income }}</p>
			<p><strong>Address:</strong> {{ selectedTraveler.address }}</p>
			<!-- You can include additional details here -->
		</div>
	</div>
</template>

<script>
export default {
	name: 'TravelersSplitView',
	props: {
		// Standard Directus interface props
		value: {
			type: [String, Number, Object, Array, Boolean],
			default: null,
		},
		interface: {
			type: Object,
			default: () => ({}),
		},
		field: {
			type: Object,
			default: () => ({}),
		},
	},
	data() {
		return {
			travelers: [],
			selectedTraveler: null,
		};
	},
	async created() {
		try {
			// Replace '/items/travelers' with your actual API endpoint or collection name
			const response = await this.$axios.get('/items/travelers');
			this.travelers = response.data.data || [];
		} catch (error) {
			console.error('Error fetching travelers:', error);
		}
	},
	methods: {
		selectTraveler(traveler) {
			this.selectedTraveler = traveler;
			// If you want to save the selected value to the Directus field:
			this.$emit('input', traveler.id);
		},
	},
};
</script>

<style scoped>
.travelers-interface {
	display: flex;
	gap: 1rem;
	align-items: flex-start;
}

.sidebar {
	width: 30%;
	border-right: 1px solid #ddd;
	padding-right: 1rem;
}

.preview {
	flex: 1;
	padding-left: 1rem;
	min-height: 200px;
	overflow: auto;
}

table {
	width: 100%;
	border-collapse: collapse;
}

tbody tr {
	cursor: pointer;
}

tbody tr.active {
	background-color: #e8f0fe;
}
</style>  