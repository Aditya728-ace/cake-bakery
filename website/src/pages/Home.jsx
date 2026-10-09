import { Link } from "react-router-dom";
import { api, img, whatsappLink } from "../api.js";
import { useFetch, useSite } from "../site.jsx";
import CakeCard from "../components/CakeCard.jsx";
import CardSkeletons from "../components/Skeleton.jsx";
import Placeholder from "../components/Placeholder.jsx";
import Reveal from "../components/Reveal.jsx";
import { Mail, Phone, Pin, Whatsapp } from "../components/Icons.jsx";

export default function Home() {
  const { bakery, content } = useSite();
  const featured = useFetch(async () => {
    const f = await api.cakes(true);
    return f.length ? f.slice(0, 3) : (await api.cakes(false)).slice(0, 3);
  }, []);
  const wa = bakery && whatsappLink(bakery.whatsapp_number, bakery.name);
  const aboutParas = (content.about_body || "").split(/\n\s*\n/).filter(Boolean);

  return (
    <>
      <section className="hero">
        <div className="container hero-grid">
          <div className="hero-text">
            <span className="script">{bakery?.tagline || "Baked with love"}</span>
            <h1>{content.hero_title || "Handcrafted cakes for life's sweetest moments"}</h1>
            <p className="lead">{content.hero_subtitle || "Made to order, finished by hand, delivered with care."}</p>
            <div className="hero-actions">
              <Link to="/cakes" className="btn">{content.hero_cta_label || "Explore our cakes"}</Link>
              {wa && <a href={wa} className="btn btn-ghost" target="_blank" rel="noopener noreferrer"><Whatsapp /> Chat with us</a>}
            </div>
          </div>
          <div className="hero-art">
            <div className="arch">
              {content.hero_image_url ? <img src={img(content.hero_image_url, 900)} alt="" /> : <Placeholder />}
            </div>
            <div className="hero-badge script">Made fresh<br />to order</div>
          </div>
        </div>
      </section>

      <section className="section intro">
        <Reveal className="container narrow center">
          <span className="script">Our story</span>
          <h2>{content.about_title || `Welcome to ${bakery?.name || "our bakery"}`}</h2>
          {aboutParas.length ? aboutParas.map((p, i) => <p key={i} className="lead">{p}</p>)
            : <p className="lead">Every cake is baked from scratch with real butter, fine chocolate and fresh ingredients.</p>}
          <div className="ornament" aria-hidden="true">✦</div>
        </Reveal>
      </section>

      <section className="section alt">
        <div className="container">
          <Reveal className="center head">
            <span className="script">Fresh from the oven</span>
            <h2>Featured cakes</h2>
          </Reveal>
          {featured.loading ? <CardSkeletons /> : featured.data?.length ? (
            <div className="grid">
              {featured.data.map((c, i) => <Reveal key={c.id} delay={i * 90}><CakeCard cake={c} /></Reveal>)}
            </div>
          ) : <p className="center muted">Our collection is being baked. Please check back soon!</p>}
          <div className="center" style={{ marginTop: 40 }}><Link to="/cakes" className="btn btn-ghost">See all cakes</Link></div>
        </div>
      </section>

      <section className="section" id="contact">
        <div className="container">
          <Reveal className="center head">
            <span className="script">Let's celebrate</span>
            <h2>Order or enquire</h2>
            <p className="lead narrow">Tell us the occasion, the date and your dream flavours. We'll take care of the rest.</p>
          </Reveal>
          {bakery && (
            <Reveal className="contact-cards">
              {wa && <a className="contact-card" href={wa} target="_blank" rel="noopener noreferrer"><Whatsapp /><b>WhatsApp</b><span>Message us</span></a>}
              {bakery.phone && <a className="contact-card" href={`tel:${bakery.phone.replace(/\s/g, "")}`}><Phone /><b>Call</b><span>{bakery.phone}</span></a>}
              {bakery.email && <a className="contact-card" href={`mailto:${bakery.email}`}><Mail /><b>Email</b><span>{bakery.email}</span></a>}
              {bakery.address && <div className="contact-card"><Pin /><b>Visit</b><span>{bakery.address}</span></div>}
            </Reveal>
          )}
        </div>
      </section>
    </>
  );
}
