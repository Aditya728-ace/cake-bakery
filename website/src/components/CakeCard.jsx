import { Link } from "react-router-dom";
import { img, money } from "../api.js";
import Placeholder from "./Placeholder.jsx";

export default function CakeCard({ cake }) {
  const price = money(cake.price, cake.currency);
  return (
    <Link to={`/cakes/${cake.slug}`} className="card">
      <div className="card-img">
        {cake.cover_url ? <img src={img(cake.cover_url, 640)} alt={cake.title} loading="lazy" /> : <Placeholder label={cake.title} />}
        {!cake.is_available && <span className="tag">Sold out</span>}
      </div>
      <div className="card-body">
        <h3>{cake.title}</h3>
        <p className="clamp">{cake.description}</p>
        <div className="card-foot">
          <span className="price">{price || "Price on request"}</span>
          <span className="more">View details →</span>
        </div>
      </div>
    </Link>
  );
}
