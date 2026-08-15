const githubUrl = "https://github.com/JhonatanC4STRO/Notium";
const apkDownloadUrl = `${githubUrl}/releases/latest/download/notium-v1.0.0.apk`;
const apiHealthUrl = "https://api.notium.shona.lat/v1/health";

const features = [
  {
    number: "01",
    title: "Funciona sin señal",
    text: "Crear, editar, buscar y adjuntar archivos sigue disponible incluso en modo avión.",
  },
  {
    number: "02",
    title: "Datos cifrados",
    text: "SQLCipher protege la base local y Android Keystore resguarda las credenciales.",
  },
  {
    number: "03",
    title: "Sincronización confiable",
    text: "Push, pull, reintentos e idempotencia mantienen cada dispositivo al día.",
  },
  {
    number: "04",
    title: "Conflictos con historia",
    text: "Last-Write-Wins resuelve cambios simultáneos sin borrar la trazabilidad del valor descartado.",
  },
];

const stack = [
  "Flutter",
  "Riverpod",
  "Drift",
  "SQLCipher",
  "Dio",
  "WorkManager",
  "Node.js",
  "Express",
  "PostgreSQL",
  "Docker",
  "OpenAPI",
];

export default function Home() {
  return (
    <main>
      <nav className="nav shell" aria-label="Navegación principal">
        <a className="brand" href="#inicio" aria-label="Notium, volver al inicio">
          <span className="brand-mark">N</span>
          <span>NOTIUM</span>
        </a>
        <div className="nav-links">
          <a href="#arquitectura">Arquitectura</a>
          <a href="#tecnologia">Tecnología</a>
          <a href={githubUrl} target="_blank" rel="noreferrer">
            GitHub ↗
          </a>
        </div>
      </nav>

      <section className="hero shell" id="inicio">
        <div className="hero-copy">
          <p className="eyebrow"><span /> Android · Offline-first</p>
          <h1>
            Tus notas no
            <br /> deberían esperar
            <br /> <em>por la red.</em>
          </h1>
          <p className="hero-lead">
            Notium es una aplicación Android que trabaja primero en el dispositivo
            y sincroniza después. Rápida, cifrada y preparada para conexiones reales.
          </p>
          <div className="hero-actions">
            <a className="button button-primary" href={apkDownloadUrl}>
              Descargar APK <span>↓</span>
            </a>
            <a className="button button-ghost" href={githubUrl} target="_blank" rel="noreferrer">
              Ver el código <span>↗</span>
            </a>
          </div>
          <div className="hero-proof" aria-label="Resumen técnico">
            <div><strong>API 24+</strong><span>Android 7 o superior</span></div>
            <div><strong>100% offline</strong><span>Operación local continua</span></div>
            <div><strong>Open source</strong><span>Arquitectura documentada</span></div>
          </div>
        </div>

        <div className="hero-visual" aria-label="Vista conceptual de la aplicación Notium">
          <div className="orbit orbit-one" />
          <div className="orbit orbit-two" />
          <div className="sync-chip"><i /> Sincronizado</div>
          <div className="offline-chip">Modo offline</div>
          <div className="phone-shadow" />
          <div className="phone">
            <div className="phone-speaker" />
            <div className="phone-screen">
              <div className="phone-status"><span>9:41</span><span>● ◒</span></div>
              <div className="app-header">
                <div><small>BUEN DÍA</small><strong>Mis notas</strong></div>
                <span className="avatar">JC</span>
              </div>
              <div className="search">⌕&nbsp;&nbsp; Buscar en tus notas</div>
              <div className="note-card featured-note">
                <div className="note-top"><span className="note-tag cyan">PROYECTO</span><span>•••</span></div>
                <h3>Arquitectura offline-first</h3>
                <p>La interfaz siempre consulta la base local. La red llega después.</p>
                <footer><span>Hoy, 9:24</span><span className="synced-dot">✓</span></footer>
              </div>
              <div className="note-card">
                <div className="note-top"><span className="note-tag blue">IDEAS</span><span>•••</span></div>
                <h3>Próxima iteración</h3>
                <p>Probar el flujo entre dos dispositivos...</p>
                <footer><span>Ayer</span><span className="pending-dot">↻</span></footer>
              </div>
              <button className="fab" aria-label="Crear una nota" tabIndex={-1}>＋</button>
              <div className="phone-nav"><span className="active">▤<small>Notas</small></span><span>↻<small>Sync</small></span><span>◷<small>Historial</small></span></div>
            </div>
          </div>
        </div>
      </section>

      <div className="ticker" aria-hidden="true">
        <div>OFFLINE-FIRST <span>✦</span> CIFRADO LOCAL <span>✦</span> SINCRONIZACIÓN AUTOMÁTICA <span>✦</span> HISTORIAL AUDITABLE <span>✦</span></div>
      </div>

      <section className="statement shell section-pad">
        <p className="section-kicker">El problema</p>
        <div className="statement-grid">
          <h2>La conectividad es una variable, no un requisito.</h2>
          <div>
            <p>
              Muchas aplicaciones móviles dejan de ser útiles cuando la red falla.
              Notium invierte esa dependencia: cada acción se confirma localmente en
              milisegundos y la sincronización ocurre cuando es posible.
            </p>
            <p className="statement-note">Diseñada para trabajo de campo, movilidad y conexiones inestables.</p>
          </div>
        </div>
      </section>

      <section className="features shell" aria-labelledby="features-title">
        <div className="section-heading">
          <p className="section-kicker">Capacidades</p>
          <h2 id="features-title">Hecha para seguir trabajando.</h2>
        </div>
        <div className="feature-grid">
          {features.map((feature) => (
            <article className="feature-card" key={feature.number}>
              <span className="feature-number">{feature.number}</span>
              <div className="feature-icon" aria-hidden="true">{feature.number === "01" ? "⌁" : feature.number === "02" ? "◇" : feature.number === "03" ? "↻" : "◷"}</div>
              <h3>{feature.title}</h3>
              <p>{feature.text}</p>
            </article>
          ))}
        </div>
      </section>

      <section className="architecture section-pad" id="arquitectura">
        <div className="shell">
          <div className="architecture-intro">
            <div>
              <p className="section-kicker light">Arquitectura</p>
              <h2>Local primero.<br />Red después.</h2>
            </div>
            <p>
              La base cifrada es la única fuente de verdad para la interfaz. Un
              coordinador independiente mueve cambios entre el dispositivo y el
              servidor sin bloquear al usuario.
            </p>
          </div>

          <div className="architecture-board" role="img" aria-label="Flujo de arquitectura: aplicación Flutter, base local cifrada, coordinador de sincronización, API Node y PostgreSQL">
            <div className="arch-node arch-device">
              <small>DISPOSITIVO ANDROID</small>
              <strong>Flutter + Riverpod</strong>
              <span>Interfaz reactiva</span>
            </div>
            <div className="arch-link"><span>PERSISTE</span><i>→</i></div>
            <div className="arch-node arch-local">
              <small>FUENTE DE VERDAD</small>
              <strong>Drift + SQLCipher</strong>
              <span>Datos cifrados en reposo</span>
            </div>
            <div className="arch-link arch-link-network"><span>HTTPS · PUSH / PULL</span><i>⇄</i></div>
            <div className="arch-node arch-api">
              <small>AUTORIDAD DE SYNC</small>
              <strong>Node.js + Express</strong>
              <span>JWT · LWW · Idempotencia</span>
            </div>
            <div className="arch-link"><span>CONSULTA</span><i>→</i></div>
            <div className="arch-node arch-server">
              <small>PERSISTENCIA REMOTA</small>
              <strong>PostgreSQL</strong>
              <span>Estado consolidado + adjuntos</span>
            </div>
          </div>

          <div className="architecture-notes">
            <div><span>01</span><p><strong>Respuesta inmediata</strong>La UI nunca espera una petición HTTP para guardar.</p></div>
            <div><span>02</span><p><strong>Convergencia</strong>WorkManager sincroniza al recuperar conectividad.</p></div>
            <div><span>03</span><p><strong>Conflictos visibles</strong>Las decisiones LWW quedan en el historial.</p></div>
          </div>
        </div>
      </section>

      <section className="sync-flow shell section-pad">
        <div className="section-heading split-heading">
          <div><p className="section-kicker">Ciclo de sincronización</p><h2>Una ruta predecible para cada cambio.</h2></div>
          <p>Los estados son explícitos. Si algo falla, la nota permanece local y el usuario conserva el control.</p>
        </div>
        <div className="flow-steps">
          <article><span>01</span><h3>Escribe local</h3><p>La operación queda en estado <code>PENDING</code>.</p></article>
          <article><span>02</span><h3>Envía cambios</h3><p>Push idempotente en lotes cuando vuelve la red.</p></article>
          <article><span>03</span><h3>Resuelve</h3><p>El servidor acepta o aplica LWW ante conflictos.</p></article>
          <article><span>04</span><h3>Converge</h3><p>Pull incremental actualiza los demás dispositivos.</p></article>
        </div>
      </section>

      <section className="technology" id="tecnologia">
        <div className="shell section-pad">
          <div className="tech-grid">
            <div className="tech-copy">
              <p className="section-kicker">Tecnología</p>
              <h2>Un sistema completo, no solo una interfaz.</h2>
              <p>
                Cliente móvil, persistencia cifrada, sincronización, autenticación,
                API, base de datos y operación en contenedores: cada capa está
                documentada y cubierta por pruebas.
              </p>
              <a href={`${githubUrl}/blob/main/doc/doc.md`} target="_blank" rel="noreferrer">Leer decisiones de arquitectura ↗</a>
            </div>
            <div className="stack-list" aria-label="Stack tecnológico">
              {stack.map((item, index) => <span key={item}><b>{String(index + 1).padStart(2, "0")}</b>{item}</span>)}
            </div>
          </div>
          <div className="quality-strip">
            <div><strong>83</strong><span>pruebas Flutter</span></div>
            <div><strong>44</strong><span>pruebas backend</span></div>
            <div><strong>4</strong><span>migraciones locales</span></div>
            <a href={apiHealthUrl} target="_blank" rel="noreferrer"><i /> API pública <span>comprobar ↗</span></a>
          </div>
        </div>
      </section>

      <section className="final-cta shell section-pad">
        <div className="cta-panel">
          <p className="section-kicker light">Código abierto</p>
          <h2>Construido para funcionar cuando internet no lo hace.</h2>
          <p>Explora el código, las pruebas, el contrato OpenAPI y las decisiones detrás de Notium.</p>
          <div className="hero-actions">
            <a className="button button-light" href={apkDownloadUrl}>Descargar para Android ↓</a>
            <a className="button button-outline-light" href={githubUrl} target="_blank" rel="noreferrer">Explorar repositorio ↗</a>
          </div>
          <div className="cta-grid" aria-hidden="true" />
        </div>
      </section>

      <footer className="footer shell">
        <a className="brand" href="#inicio"><span className="brand-mark">N</span><span>NOTIUM</span></a>
        <p>Diseñado y desarrollado por Jhonatan Castro.</p>
        <p>ADSO · SENA · 2026</p>
      </footer>
    </main>
  );
}
