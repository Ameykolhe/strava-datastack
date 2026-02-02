import {writable} from 'svelte/store';

const STORAGE_KEY = 'distanceUnit';
const isBrowser = typeof window !== 'undefined';
const initialUnit = isBrowser ? localStorage.getItem(STORAGE_KEY) || 'km' : 'km';

const distanceUnitStore = writable(initialUnit);

if (isBrowser) {
    window.addEventListener('distance-unit-change', (event) => {
        if (event?.detail?.unit) distanceUnitStore.set(event.detail.unit);
    });
}

export {distanceUnitStore};
