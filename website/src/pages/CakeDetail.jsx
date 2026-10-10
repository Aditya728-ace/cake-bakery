import { useEffect, useState } from "react";
import { Link, useParams } from "react-router-dom";
import { api, img, money, whatsappLink } from "../api.js";
import { useFetch, useSite } from "../site.jsx";
import Placeholder from "../components/Placeholder.jsx";
import NotFound from "./NotFound.jsx";
import { Whatsapp, Phone } from "../components/Icons.jsx";

export default function CakeDetail() {
  const { slug } = useParams();
  const { bakery } = useSite();
  const { data: cake, loading, error } = useFetch(() => api.cake(slug), [slug]);
  const [active, setActive] = useState(0);
  useEffect(() => {
    setActive(0);
  }, [slug]);
  useEffect(() => {
    if (cake && bakery) document.title = `${cake.title} · ${bakery.name}`;
  }, [cake, bakery]);

  if (loading) return <section className="section"><div className="container detail"><div className="skeleton big" /><div className="skeleton"><div className="card-body"><i /><i /><i /></div></div></div></section>;
  if (error?.status === 404) return <NotFound />;
  if (error) return <div className="container notice"><p>{error.message}</p></div>;

  const imgs = cake.images || [];
  const current = imgs[active];
  const price = money(cake.price, cake.currency);
  const wa = bakery && whatsappLink(bakery.whatsapp_number, bakery.name, cake.title);

  return (
    <section className="section">
      <div className="container">
        <Link to="/cakes" className="back">← All cakes</Link>
        <div className="detail">
          <div>
            <div className="detail-img">
              {current ? <img key={current.id} src={img(current.url, 1100)} alt={cake.title} width={current.width || undefined} height={current.height || undefined} /> : <Placeholder label={cake.title} />}
            </div>
            {imgs.length > 1 && (
              <div className="thumbs">
                {imgs.map((im, i) => (
                  <button key={im.id} className={i === active ? "on" : ""} onClick={() => setActive(i)} aria-label={`Photo ${i + 1}`}>
                    <img src={img(im.url, 160)} alt="" loading="lazy" />
                  </button>
                ))}
              </div>
            )}
          </div>
          <div className="detail-info">
            <span className="script">{cake.is_available ? "Baked to order" : "Currently sold out"}</span>
            <h1 className="h2">{cake.title}</h1>
            <div className="detail-price">{price || "Price on request"}</div>
            {cake.description && <p className="lead">{cake.description}</p>}
            {cake.ingredients.length > 0 && (
              <>
                <h4 className="mini">What's inside</h4>
                <ul className="chips">{cake.ingredients.map((x) => <li key={x}>{x}</li>)}</ul>
              </>
            )}
            <div className="hero-actions">
              {wa && <a className="btn" href={wa} target="_blank" rel="noopener noreferrer"><Whatsapp /> Enquire on WhatsApp</a>}
              {!wa && bakery?.phone && <a className="btn" href={`tel:${bakery.phone.replace(/\s/g, "")}`}><Phone /> Call to order</a>}
            </div>
            <p className="muted small">Flavours, sizes and designs can be customised. Just ask.</p>
          </div>
        </div>
      </div>
    </section>
  );
}
