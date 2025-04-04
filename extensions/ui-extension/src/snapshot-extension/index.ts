import { defineInterface } from '@directus/extensions-sdk';
import InterfaceComponent from './interface.vue';

export default defineInterface({
	id: 'snapshot-extension',
	name: 'Snapshot',
	icon: 'featured_video',
	description: 'This is my custom interface!',
	conditions: (context: any) => {
		console.log('Interface Extension Context:', context);

		// You can also log specific properties
		console.log('Collection:', context.collection);
		console.log('Field:', context.field);
		return true; // Apply to all collections
		// To target specific collections: return context.collection === 'your_collection_name';
	},
	component: InterfaceComponent,
	options: null,
	types: ['string', 'boolean', 'integer', 'float', 'date', 'json'], // Add valid types here
});
