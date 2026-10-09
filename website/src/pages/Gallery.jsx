import { useMemo, useState } from "react";
import { api } from "../api.js";
import { useFetch } from "../site.jsx";
import CakeCard from "../components/CakeCard.jsx";
import CardSkeletons from "../components/Skeleton.jsx";
import Reveal from "../components/Reveal.jsx";

export default function Gallery() {
  const { data, loading, error } = useFetch(() => api.cakes(false), []);
  const [q, setQ] = useState("");
  const [onlyAvail, setOnlyAvail] = useState(false);
  const list = useMemo(() => {
    const s = q.trim().toLowerCase();
    return (data || []).filter((c) =>
      (!onlyAvail || c.is_available) &&
      (!s || c.title.toLowerCase().includes(s) || c.ingredients.some((i) => i.toLowerCase().includes(s))));
  }, [data, q, onlyAvail]);

  return (
    <section className="section">
      <div className="container">
        <div className="center head">
          <span className="script">The collection</span>
          <h1 className="h2">Our cakes</h1>
          <p className="lead narrow">Each cake is baked to order. Tap one to see what's inside.</p>
        </div>
        <div className="filters">
          <input type="search" placeholder="Search by name or ingredient…" value={q} onChange={(e) => setQ(e.target.value)} aria-label="Search cakes" />
          <label className="check"><input type="checkbox" checked={onlyAvail} onChange={(e) => setOnlyAvail(e.target.checked)} /> Available now</label>
        </div>
        {loading ? <CardSkeletons n={6} /> : error ? <p className="center muted">{error.message}</p> : list.length ? (
          <div className="grid">{list.map((c, i) => <Reveal key={c.id} delay={(i % 3) * 80}><CakeCard cake={c} /></Reveal>)}</div>
        ) : <p className="center muted">{data?.length ? "No cakes match your search." : "Our collection is being baked. Please check back soon!"}</p>}
      </div>
    </section>
  );
}
