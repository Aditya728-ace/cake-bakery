export default function CardSkeletons({ n = 3 }) {
  return (
    <div className="grid">
      {Array.from({ length: n }).map((_, i) => (
        <div className="card skeleton" key={i}><div className="card-img" /><div className="card-body"><i /><i /><i /></div></div>
      ))}
    </div>
  );
}
