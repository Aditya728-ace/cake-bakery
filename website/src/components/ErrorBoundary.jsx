import { Component } from "react";

export default class ErrorBoundary extends Component {
  state = { error: null };

  static getDerivedStateFromError(error) {
    return { error };
  }

  componentDidCatch(error) {
    console.error("Page crashed:", error);
    try {
      const last = Number(sessionStorage.getItem("eb-reload") || 0);
      if (Date.now() - last > 15000) {
        sessionStorage.setItem("eb-reload", String(Date.now()));
        window.location.reload();
      }
    } catch {
      /* storage blocked */
    }
  }

  render() {
    if (!this.state.error) return this.props.children;
    return (
      <div className="container notice">
        <span className="script">Oh crumbs!</span>
        <h2>Something went wrong</h2>
        <p className="muted">Please reload the page.</p>
        <button className="btn" onClick={() => window.location.reload()}>Reload</button>
        <p className="muted small">{String(this.state.error?.message || "")}</p>
      </div>
    );
  }
}
