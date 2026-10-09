import { Link } from "react-router-dom";
export default function NotFound() {
  return (
    <section className="section">
      <div className="container notice">
        <span className="script">Oh crumbs!</span>
        <h1 className="h2">We couldn't find that page</h1>
        <p className="muted">The cake may have sold out or moved off the shelf.</p>
        <Link to="/cakes" className="btn">Browse our cakes</Link>
      </div>
    </section>
  );
}
