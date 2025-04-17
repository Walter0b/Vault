<template>
	<div class="collection-split-view" ref="interface">
		<!-- Left sidebar: table of collection rows with all columns -->
		<div class="sidebar">
			<div class="table-container">
				<table v-if="items.length > 0 && collectionFields.length > 0">
					<thead>
						<tr>
							<!-- Dynamically generate headers for all fields -->
							<th v-for="field in collectionFields" :key="field.field" @click="sortBy(field.field)"
								class="sortable">
								{{ field.name || field.field }}
								<span v-if="sortField === field.field">
									{{ sortDirection === 'asc' ? '▲' : '▼' }}
								</span>
							</th>
						</tr>
					</thead>
					<tbody>
						<tr v-for="item in items" :key="item.id" @click="selectItem(item)"
							:class="{ active: item.id === selectedItem?.id }">
							<!-- Display value for each field -->
							<td v-for="field in collectionFields" :key="field.field">
								{{ formatValue(item[field.field], field) }}
							</td>
						</tr>
					</tbody>
				</table>
				<div v-else-if="loading" class="loading-state">
					Loading data...
				</div>
				<div v-else class="empty-state-message">
					No data available
				</div>
			</div>

			<!-- Pagination controls -->
			<div class="pagination-controls">
				<button class="pagination-button" :disabled="page <= 1" @click="changePage(page - 1)">
					Previous
				</button>
				<span class="pagination-info">Page {{ page }} of {{ totalPages || 1 }}</span>
				<button class="pagination-button" :disabled="page >= totalPages" @click="changePage(page + 1)">
					Next
				</button>
			</div>
		</div>

		<!-- Right panel: detailed preview of selected item -->
		<div class="preview" v-if="selectedItem">
			<h2>{{ selectedItem[primaryField] || selectedItem.id }}</h2>

			<div class="preview-content">
				<div v-for="field in collectionFields" :key="field.field" class="field-row">
					<div class="field-label">{{ field.name || field.field }}:</div>
					<div class="field-value">
						{{ formatValue(selectedItem[field.field], field) }}
					</div>
				</div>
			</div>
		</div>

		<div class="preview empty-state" v-else>
			<div class="empty-state-message">
				<span>Select an item to view details</span>
			</div>
		</div>
	</div>
</template>

<script>
import { defineComponent } from 'vue';
import { useApi } from '@directus/extensions-sdk';

export default defineComponent({
	name: "CollectionSplitView",
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
		collection: {
			type: String,
			default: null,
		},
	},
	setup() {
		// Get API client using the composable
		const api = useApi();
		return { api };
	},
	data() {
		return {
			items: [],
			collectionFields: [],
			selectedItem: null,
			primaryField: "id",
			loading: false,
			styleId: 'split-view-styles-' + Math.random().toString(36).substring(2, 9), // Unique ID to avoid conflicts
			page: 1,
			limit: 20, // Items per page
			totalItems: 0,
			totalPages: 0,
			sortField: null,
			sortDirection: 'asc',
		};
	},
	computed: {
		collectionName() {
			return this.collection || (this.field && this.field.collection);
		}
	},
	async created() {
		// Get collection details and data first
		if (this.collectionName) {
			await this.fetchCollectionInfo();
			await this.fetchItems();

			// If we have a value from the parent form, select that item
			if (this.value) {
				this.selectItemById(this.value);
			}
		} else {
			console.error("Collection name not found");
		}
	},
	mounted() {
		// Apply once component is mounted to DOM
		this.$nextTick(() => {
			this.makeInterfaceFullScreen();
		});
	},
	methods: {
		sortBy(field) {
			if (this.sortField === field) {
				this.sortDirection = this.sortDirection === 'asc' ? 'desc' : 'asc';
			} else {
				this.sortField = field;
				this.sortDirection = 'asc';
			}
			this.items.sort((a, b) => {
				const valA = a[field];
				const valB = b[field];
				if (valA < valB) return this.sortDirection === 'asc' ? -1 : 1;
				if (valA > valB) return this.sortDirection === 'asc' ? 1 : -1;
				return 0;
			});
		},
		async fetchCollectionInfo() {
			try {
				this.loading = true;

				if (!this.collectionName) {
					console.error("Collection name not found");
					return;
				}

				console.log("Collection name:", this.collectionName);

				// Get collection fields
				const fieldsResponse = await this.api.get(`/fields/${this.collectionName}`);

				// Debug output to verify data structure
				console.log("Fields response:", fieldsResponse);

				if (fieldsResponse.data && fieldsResponse.data.data) {
					this.collectionFields = fieldsResponse.data.data;
					console.log("Collection fields loaded:", this.collectionFields.length);
				} else {
					console.error("Unexpected fields response structure:", fieldsResponse);
				}

				// Find primary display field
				const collectionsResponse = await this.api.get(`/collections/${this.collectionName}`);
				const collectionInfo = collectionsResponse.data.data;

				if (collectionInfo && collectionInfo.meta && collectionInfo.meta.display_template) {
					// If there's a display template, use the first field in it
					const displayTemplate = collectionInfo.meta.display_template;
					const match = displayTemplate.match(/\{\{([^}]+)\}\}/);
					if (match && match[1]) {
						this.primaryField = match[1].trim();
					}
				}
			} catch (error) {
				console.error("Error fetching collection info:", error);
			} finally {
				this.loading = false;
			}
		},
		async fetchItems() {
			try {
				this.loading = true;

				if (!this.collectionName) {
					console.error("Collection name not found");
					return;
				}

				console.log("Fetching items from collection:", this.collectionName);

				// Get items with pagination
				const params = {
					limit: this.limit,
					page: this.page,
					meta: 'filter_count,total_count',
				};

				const response = await this.api.get(`/items/${this.collectionName}`, { params });

				console.log("Items response:", response);

				if (response.data && response.data.data) {
					this.items = response.data.data;

					// Get total items and calculate total pages
					if (response.data.meta && response.data.meta.total_count) {
						this.totalItems = response.data.meta.total_count;
						this.totalPages = Math.ceil(this.totalItems / this.limit);
					}

					console.log(`Items loaded: ${this.items.length} (Page ${this.page}/${this.totalPages})`);
				} else {
					console.error("Unexpected items response structure:", response);
				}
			} catch (error) {
				console.error("Error fetching items:", error);
			} finally {
				this.loading = false;
			}
		},
		async changePage(newPage) {
			if (newPage >= 1 && newPage <= this.totalPages) {
				this.page = newPage;
				// Clear selection when changing pages
				this.selectedItem = null;
				await this.fetchItems();
			}
		},
		selectItem(item) {
			this.selectedItem = item;
			// Emit the selected item's ID to update the field value
			this.$emit("input", item.id);
		},
		selectItemById(id) {
			const item = this.items.find(item => item.id === id);
			if (item) {
				this.selectedItem = item;
			} else {
				// If item not in current page, try to fetch it specifically
				this.fetchSpecificItem(id);
			}
		},
		async fetchSpecificItem(id) {
			try {
				const response = await this.api.get(`/items/${this.collectionName}/${id}`);
				if (response.data && response.data.data) {
					this.selectedItem = response.data.data;
				}
			} catch (error) {
				console.error(`Error fetching item with ID ${id}:`, error);
			}
		},
		formatValue(value, field) {
			if (value === null || value === undefined) {
				return '—';
			}

			// Format based on field type
			if (field && field.type) {
				switch (field.type) {
					case 'date':
						return new Date(value).toLocaleDateString();
					case 'datetime':
						return new Date(value).toLocaleString();
					case 'boolean':
						return value ? 'Yes' : 'No';
					case 'json':
						return typeof value === 'object' ? 'JSON Data' : value;
					default:
						if (typeof value === 'object') {
							return JSON.stringify(value).substring(0, 50) + (JSON.stringify(value).length > 50 ? '...' : '');
						}
						return value;
				}
			} else {
				// If field type is not available, do basic formatting
				if (typeof value === 'object') {
					return JSON.stringify(value).substring(0, 50) + (JSON.stringify(value).length > 50 ? '...' : '');
				}
				return String(value);
			}
		},
		makeInterfaceFullScreen() {
			// Traverse up from our component to find the form container
			let el = this.$refs.interface;
			let formGrid = null;

			// Find the parent .v-form or .v-form.grid container
			while (el && !formGrid) {
				el = el.parentElement;
				if (el && (el.classList.contains('v-form') ||
					(el.classList.contains('v-form') && el.classList.contains('grid')))) {
					formGrid = el;
					break;
				}
			}

			if (!formGrid) {
				console.warn("Form grid not found");
				return; // Exit if no form found
			}

			// Find our field container (usually 2-3 levels up from our interface)
			let fieldContainer = this.$refs.interface;
			while (fieldContainer && !fieldContainer.classList.contains('field')) {
				fieldContainer = fieldContainer.parentElement;
			}

			if (!fieldContainer) {
				console.warn("Field container not found");
				return; // Exit if can't find our field container
			}

			// Add class to our container
			fieldContainer.classList.add('split-view-fullscreen');

			// Create style to affect the form layout
			const styleElement = document.createElement('style');
			styleElement.id = this.styleId;
			styleElement.textContent = `
				/* Hide all other fields except our split view field */
				.v-form .field:not(.split-view-fullscreen) {
					display: none !important;
				}
				
				/* Make our field take full width and height */
				.v-form .split-view-fullscreen {
					grid-column: 1 / -1 !important; 
					width: 100% !important;
					max-width: 100% !important;
					height: calc(100vh - 130px) !important;
				}
				
				/* Make the actual interface container take the full height */
				.split-view-fullscreen .collection-split-view {
					height: 100%;
				}
				
				/* Fix any potential overflow issues */
				.v-form {
					overflow: visible !important;
				}
			`;

			document.head.appendChild(styleElement);
		}
	},
	// Clean up
	beforeUnmount() {  // Updated from beforeDestroy to beforeUnmount for Vue 3
		const styleElement = document.getElementById(this.styleId);
		if (styleElement) {
			styleElement.remove();
		}
	}
});
</script>

<style scoped>
.collection-split-view {
	display: flex;
	gap: 1rem;
	align-items: stretch;
	height: 100%;
	background-color: var(--background-page);
	border-radius: var(--border-radius);
	overflow: hidden;
}

.sidebar {
	width: 60%;
	border-right: 1px solid var(--border-normal);
	overflow: hidden;
	display: flex;
	flex-direction: column;
}

.table-container {
	overflow: auto;
	height: calc(100% - 44px);
	/* Adjust for pagination controls */
	min-height: 200px;
}

.loading-state,
.empty-state-message {
	display: flex;
	align-items: center;
	justify-content: center;
	height: 100%;
	color: var(--foreground-subdued);
	font-style: italic;
}

.preview {
	flex: 1;
	padding: 20px;
	overflow: auto;
	background-color: var(--background-subdued);
}

.preview h2 {
	margin-top: 0;
	margin-bottom: 20px;
	padding-bottom: 10px;
	border-bottom: 1px solid var(--border-normal);
}

.preview-content {
	display: flex;
	flex-direction: column;
	gap: 12px;
}

.field-row {
	display: flex;
	align-items: flex-start;
}

.field-label {
	min-width: 120px;
	font-weight: 600;
	color: var(--foreground-subdued);
}

.field-value {
	flex: 1;
	word-break: break-word;
}

.empty-state {
	display: flex;
	align-items: center;
	justify-content: center;
}

.empty-state-message {
	color: var(--foreground-subdued);
	font-style: italic;
}

table {
	width: 100%;
	border-collapse: collapse;
	font-size: 14px;
}

thead th {
	position: sticky;
	top: 0;
	background-color: var(--background-page);
	padding: 10px;
	text-align: left;
	font-weight: 600;
	border-bottom: 1px solid var(--border-normal);
	z-index: 1;
}

tbody td {
	padding: 8px 10px;
	border-bottom: 1px solid var(--border-subdued);
	white-space: nowrap;
	overflow: hidden;
	text-overflow: ellipsis;
	max-width: 200px;
}

tbody tr:hover {
	background-color: var(--background-normal-alt);
	border-left: 4px solid var(--primary);
}

.field-row {
	display: grid;
	grid-template-columns: 140px 1fr;
	gap: 8px;
}

.preview {
	transition: all 0.2s ease-in-out;
}

.preview {
	transition: all 0.2s ease-in-out;
}


tbody tr {
	cursor: pointer;
	transition: background-color 0.1s ease;
}

tbody tr:hover {
	background-color: var(--background-normal-alt);
}

tbody tr.active {
	background-color: var(--primary-alt);
}

/* Pagination styles */
.pagination-controls {
	display: flex;
	align-items: center;
	justify-content: center;
	padding: 8px;
	border-top: 1px solid var(--border-subdued);
	background-color: var(--background-subdued);
	height: 44px;
}

.pagination-button {
	padding: 4px 8px;
	background-color: var(--background-normal);
	border: 1px solid var(--border-normal);
	border-radius: var(--border-radius);
	color: var(--foreground-normal);
	cursor: pointer;
	transition: background-color 0.1s ease;
}

.pagination-button:hover:not(:disabled) {
	background-color: var(--background-normal-alt);
}

.pagination-button:disabled {
	opacity: 0.5;
	cursor: not-allowed;
}

.pagination-info {
	margin: 0 10px;
	color: var(--foreground-subdued);
	font-size: 14px;
}
</style>