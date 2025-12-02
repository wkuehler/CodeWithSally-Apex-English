import { LightningElement, track } from 'lwc';

/**
 * CursorDemo Component
 * 
 * This component demonstrates three Cursor AI features:
 * 1. Ask Feature: Complex JavaScript logic for data processing
 * 2. Edit Feature: CSS variables defined in :host section
 * 3. Agent Feature: CSS variables used across CSS, HTML, and JS files
 */

export default class CursorDemo extends LightningElement {
    // CSS Variable Names - Agent Feature Demo (used across files)
    // These match the CSS variables in cursorDemo.css
    static CSS_VARS = {
        PRIMARY_COLOR: '--sally-primary-color',
        SECONDARY_COLOR: '--secondary-color',
        ACCENT_COLOR: '--accent-color',
        SUCCESS_COLOR: '--success-color',
        WARNING_COLOR: '--warning-color',
        ERROR_COLOR: '--error-color',
        BG_PRIMARY: '--bg-primary',
        BG_SECONDARY: '--bg-secondary',
        TEXT_PRIMARY: '--text-primary',
        TEXT_SECONDARY: '--text-secondary',
        BORDER_COLOR: '--border-color',
        BORDER_RADIUS: '--border-radius'
    };

    @track threshold = 50;
    @track rawData = [];
    @track processedData = [];
    @track displayItems = [];
    @track processedCount = 0;
    @track filteredCount = 0;
    @track averageValue = 0;

    // Dynamic styling using CSS variables - Agent Feature Demo
    get statCardStyle1() {
        return `background-color: var(${CursorDemo.CSS_VARS.BG_PRIMARY}); 
                border-color: var(${CursorDemo.CSS_VARS.PRIMARY_COLOR});`;
    }

    get statCardStyle2() {
        return `background-color: var(${CursorDemo.CSS_VARS.BG_SECONDARY}); 
                border-color: var(${CursorDemo.CSS_VARS.SECONDARY_COLOR});`;
    }

    get statCardStyle3() {
        return `background-color: var(${CursorDemo.CSS_VARS.BG_PRIMARY}); 
                border-color: var(${CursorDemo.CSS_VARS.ACCENT_COLOR});`;
    }

    get hasResults() {
        return this.displayItems && this.displayItems.length > 0;
    }

    /**
     * ASK FEATURE DEMO - Complex JavaScript Logic
     * 
     * This method demonstrates complex data processing that can be explained via Cursor's Ask feature.
     * It includes: data generation, filtering, transformation, aggregation, and sorting algorithms.
     */
    processData() {
        // Step 1: Generate synthetic data using a pseudo-random algorithm
        this.rawData = this.generateSyntheticData(100);
        
        // Step 2: Apply multi-stage filtering pipeline
        const filtered = this.applyFilterPipeline(this.rawData, this.threshold);
        
        // Step 3: Transform and enrich data with computed properties
        const transformed = this.transformAndEnrich(filtered);
        
        // Step 4: Perform statistical aggregation
        const stats = this.calculateStatistics(transformed);
        
        // Step 5: Sort using custom comparator with multiple criteria
        const sorted = this.multiCriteriaSort(transformed);
        
        // Step 6: Apply final formatting and categorization
        this.displayItems = this.categorizeAndFormat(sorted);
        
        // Update display metrics
        this.processedCount = this.rawData.length;
        this.filteredCount = filtered.length;
        this.averageValue = stats.average.toFixed(2);
        
        this.processedData = transformed;
    }

    /**
     * Generates synthetic data using a combination of algorithms
     * Uses linear congruential generator for pseudo-randomness with seed
     */
    generateSyntheticData(count) {
        const data = [];
        let seed = Date.now() % 10000;
        
        for (let i = 0; i < count; i++) {
            // Linear congruential generator: (a * seed + c) % m
            seed = (seed * 1664525 + 1013904223) % Math.pow(2, 32);
            const normalized = seed / Math.pow(2, 32);
            
            // Apply transformation to create realistic distribution
            const value = Math.floor(normalized * 200) + 1;
            const category = ['A', 'B', 'C', 'D', 'E'][Math.floor(normalized * 5)];
            
            data.push({
                id: `ITEM-${String(i + 1).padStart(4, '0')}`,
                value: value,
                category: category,
                timestamp: Date.now() - (normalized * 86400000 * 30), // Random date within last 30 days
                weight: normalized * 10
            });
        }
        
        return data;
    }

    /**
     * Multi-stage filtering pipeline with chained operations
     * Demonstrates functional programming patterns
     */
    applyFilterPipeline(data, threshold) {
        return data
            .filter(item => item.value > 0) // Remove invalid values
            .filter(item => item.value <= threshold * 2) // Upper bound filter
            .filter(item => {
                // Complex filter: keep items that are either above threshold OR in specific categories
                return item.value >= threshold || ['A', 'B'].includes(item.category);
            })
            .filter((item, index, array) => {
                // Deduplication: remove items with duplicate values in sequence
                return index === 0 || item.value !== array[index - 1].value;
            });
    }

    /**
     * Transform and enrich data with computed properties
     * Uses map-reduce patterns and conditional logic
     */
    transformAndEnrich(data) {
        const maxValue = Math.max(...data.map(item => item.value));
        const minValue = Math.min(...data.map(item => item.value));
        const range = maxValue - minValue || 1; // Avoid division by zero
        
        return data.map(item => {
            // Normalize value to 0-1 range
            const normalized = (item.value - minValue) / range;
            
            // Calculate percentile rank
            const percentile = (data.filter(d => d.value <= item.value).length / data.length) * 100;
            
            // Determine status based on multiple conditions
            let status = 'normal';
            if (percentile >= 90) status = 'high';
            else if (percentile <= 10) status = 'low';
            else if (normalized > 0.7) status = 'elevated';
            
            // Calculate weighted score
            const weightedScore = (item.value * 0.6) + (normalized * 100 * 0.4);
            
            return {
                ...item,
                normalized: normalized,
                percentile: percentile,
                status: status,
                weightedScore: weightedScore,
                displayValue: item.value.toLocaleString('en-US', { 
                    minimumFractionDigits: 0, 
                    maximumFractionDigits: 2 
                })
            };
        });
    }

    /**
     * Calculate statistical aggregations
     * Implements multiple statistical measures
     */
    calculateStatistics(data) {
        if (data.length === 0) {
            return { average: 0, median: 0, stdDev: 0, mode: 0 };
        }
        
        const values = data.map(item => item.value);
        const sortedValues = [...values].sort((a, b) => a - b);
        
        // Mean (average)
        const sum = values.reduce((acc, val) => acc + val, 0);
        const average = sum / values.length;
        
        // Median
        const mid = Math.floor(sortedValues.length / 2);
        const median = sortedValues.length % 2 === 0
            ? (sortedValues[mid - 1] + sortedValues[mid]) / 2
            : sortedValues[mid];
        
        // Standard deviation
        const variance = values.reduce((acc, val) => acc + Math.pow(val - average, 2), 0) / values.length;
        const stdDev = Math.sqrt(variance);
        
        // Mode (most frequent value)
        const frequencyMap = {};
        values.forEach(val => {
            frequencyMap[val] = (frequencyMap[val] || 0) + 1;
        });
        const mode = Object.keys(frequencyMap).reduce((a, b) => 
            frequencyMap[a] > frequencyMap[b] ? a : b
        );
        
        return { average, median, stdDev, mode: parseInt(mode) };
    }

    /**
     * Multi-criteria sorting algorithm
     * Sorts by multiple fields with different priorities
     */
    multiCriteriaSort(data) {
        return [...data].sort((a, b) => {
            // Primary sort: by status (high > elevated > normal > low)
            const statusOrder = { high: 4, elevated: 3, normal: 2, low: 1 };
            const statusDiff = (statusOrder[b.status] || 0) - (statusOrder[a.status] || 0);
            if (statusDiff !== 0) return statusDiff;
            
            // Secondary sort: by weighted score (descending)
            const scoreDiff = b.weightedScore - a.weightedScore;
            if (scoreDiff !== 0) return scoreDiff;
            
            // Tertiary sort: by value (descending)
            const valueDiff = b.value - a.value;
            if (valueDiff !== 0) return valueDiff;
            
            // Final sort: by ID (ascending, lexicographic)
            return a.id.localeCompare(b.id);
        });
    }

    /**
     * Categorize and format items for display
     * Applies final transformations and adds display properties
     */
    categorizeAndFormat(data) {
        return data.map((item, index) => {
            // Determine display category based on percentile
            let displayCategory = 'standard';
            if (item.percentile >= 75) displayCategory = 'premium';
            else if (item.percentile <= 25) displayCategory = 'basic';
            
            return {
                ...item,
                displayCategory: displayCategory,
                rank: index + 1,
                formattedPercentile: `${item.percentile.toFixed(1)}%`
            };
        });
    }

    /**
     * Dynamic styling method using CSS variables - Agent Feature Demo
     * Returns inline styles based on item status
     */
    getItemStyle(item) {
        const baseStyle = `border-left: 4px solid var(${CursorDemo.CSS_VARS.BORDER_COLOR});`;
        
        let colorVar = CursorDemo.CSS_VARS.PRIMARY_COLOR;
        if (item.status === 'high') {
            colorVar = CursorDemo.CSS_VARS.ERROR_COLOR;
        } else if (item.status === 'elevated') {
            colorVar = CursorDemo.CSS_VARS.WARNING_COLOR;
        } else if (item.status === 'low') {
            colorVar = CursorDemo.CSS_VARS.SUCCESS_COLOR;
        }
        
        return `${baseStyle} border-left-color: var(${colorVar});`;
    }

    handleThresholdChange(event) {
        this.threshold = parseInt(event.target.value) || 50;
    }
}

