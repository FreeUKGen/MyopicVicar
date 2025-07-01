// Auto-scroll (lazy loading) functionality for search results
class AutoScroll {
  constructor(options = {}) {
    this.options = {
      container: '.results',
      loadingElement: '.loading-indicator',
      threshold: 100, // pixels from bottom to trigger load
      pageSize: 50,
      debug: false, // Enable debug logging
      ...options
    };
    
    this.isLoading = false;
    this.hasMoreResults = true;
    this.currentPage = 1;
    this.searchQueryId = null;
    this.init();
  }

  init() {
    this.container = document.querySelector(this.options.container);
    this.loadingElement = document.querySelector(this.options.loadingElement);
    
    if (!this.container) {
      console.warn('AutoScroll: Container not found');
      return;
    }

    // Extract search query ID from URL or data attribute
    this.searchQueryId = this.extractSearchQueryId();
    
    if (!this.searchQueryId) {
      console.warn('AutoScroll: Search query ID not found');
      return;
    }

    this.log('AutoScroll initialized for search query:', this.searchQueryId);
    this.bindEvents();
    this.hideLoadingIndicator();
  }

  log(...args) {
    if (this.options.debug) {
      console.log('AutoScroll:', ...args);
    }
  }

  extractSearchQueryId() {
    // Try to get from data attribute first
    const dataId = this.container.dataset.searchQueryId;
    if (dataId) return dataId;

    // Extract from URL path
    const pathMatch = window.location.pathname.match(/\/search_queries\/([^\/]+)/);
    if (pathMatch) return pathMatch[1];

    return null;
  }

  bindEvents() {
    // Throttled scroll handler for better performance
    let scrollTimeout;
    window.addEventListener('scroll', () => {
      if (scrollTimeout) return;
      
      scrollTimeout = setTimeout(() => {
        this.handleScroll();
        scrollTimeout = null;
      }, 100);
    });

    // Also listen for resize events
    window.addEventListener('resize', () => {
      this.handleScroll();
    });

    this.log('Event listeners bound');
  }

  handleScroll() {
    if (this.isLoading || !this.hasMoreResults) return;

    const scrollTop = window.pageYOffset || document.documentElement.scrollTop;
    const windowHeight = window.innerHeight;
    const documentHeight = document.documentElement.scrollHeight;
    const scrollBottom = scrollTop + windowHeight;

    // Check if we're near the bottom
    if (documentHeight - scrollBottom <= this.options.threshold) {
      this.log('Near bottom, loading more results...');
      this.loadMoreResults();
    }
  }

  async loadMoreResults() {
    if (this.isLoading) {
      this.log('Already loading, skipping...');
      return;
    }

    this.isLoading = true;
    this.showLoadingIndicator();

    try {
      const response = await this.fetchMoreResults();
      
      if (response.success) {
        this.appendResults(response.html);
        this.currentPage++;
        this.hasMoreResults = response.hasMore;
        
        this.log(`Loaded page ${this.currentPage - 1}, has more: ${this.hasMoreResults}`);
        
        if (!this.hasMoreResults) {
          this.showEndMessage();
        }
      } else {
        console.error('Failed to load more results:', response.error);
        this.showErrorMessage();
      }
    } catch (error) {
      console.error('Error loading more results:', error);
      this.showErrorMessage();
    } finally {
      this.isLoading = false;
      this.hideLoadingIndicator();
    }
  }

  async fetchMoreResults() {
    const params = new URLSearchParams({
      page: this.currentPage + 1,
      results_per_page: this.options.pageSize,
      format: 'js'
    });

    const url = `/search_queries/${this.searchQueryId}/load_more?${params}`;
    
    this.log('Fetching from:', url);
    
    const response = await fetch(url, {
      method: 'GET',
      headers: {
        'X-Requested-With': 'XMLHttpRequest',
        'Accept': 'application/json'
      }
    });

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }

    return await response.json();
  }

  appendResults(html) {
    // Find the tbody element and append new rows
    const tbody = this.container.querySelector('tbody');
    if (tbody) {
      // Create a temporary container to parse the HTML
      const temp = document.createElement('div');
      temp.innerHTML = html;
      
      // Extract table rows and append them
      const newRows = temp.querySelectorAll('tr');
      this.log(`Appending ${newRows.length} new rows`);
      
      newRows.forEach(row => {
        tbody.appendChild(row.cloneNode(true));
      });
    } else {
      console.warn('AutoScroll: tbody not found');
    }
  }

  showLoadingIndicator() {
    if (this.loadingElement) {
      this.loadingElement.style.display = 'block';
    }
  }

  hideLoadingIndicator() {
    if (this.loadingElement) {
      this.loadingElement.style.display = 'none';
    }
  }

  showEndMessage() {
    // Remove any existing end message
    const existingMessage = document.querySelector('.end-message');
    if (existingMessage) {
      existingMessage.remove();
    }

    const endMessage = document.createElement('div');
    endMessage.className = 'end-message';
    endMessage.innerHTML = '<p>No more results to load.</p>';
    
    this.container.appendChild(endMessage);
    this.log('End message displayed');
  }

  showErrorMessage() {
    // Remove any existing error message
    const existingMessage = document.querySelector('.error-message');
    if (existingMessage) {
      existingMessage.remove();
    }

    const errorMessage = document.createElement('div');
    errorMessage.className = 'error-message';
    errorMessage.innerHTML = '<p>Failed to load more results. Please try again.</p>';
    
    this.container.appendChild(errorMessage);
    this.log('Error message displayed');
  }

  // Public method to refresh the scroll handler
  refresh() {
    this.currentPage = 1;
    this.hasMoreResults = true;
    this.handleScroll();
    this.log('AutoScroll refreshed');
  }
}

// Initialize auto-scroll when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
  // Check if we're on a search results page
  if (window.location.pathname.includes('/search_queries/') && 
      !window.location.pathname.includes('/new')) {
    
    new AutoScroll({
      container: '.results',
      loadingElement: '.loading-indicator',
      pageSize: 50, // Match the default results per page
      debug: false // Set to true for debugging
    });
  }
});

// Export for use in other modules
window.AutoScroll = AutoScroll; 