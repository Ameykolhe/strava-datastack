<!--
  Strava Badge
  Displays a "Follow me on Strava" badge linking to an athlete profile.

  @prop {string} athleteId - Strava athlete ID (default: "109689753")
-->
<script>
  export let athleteId = "109689753";
</script>

<div class="strava-badge-container">
  <a
      class="strava-badge"
      href="https://strava.com/athletes/{athleteId}"
      target="_blank"
      rel="noopener noreferrer"
  >
    Follow me on
    <img
        src="https://badges.strava.com/logo-strava.png"
        alt="Strava"
        class="strava-logo"
    />
  </a>
</div>

<style>
  .strava-badge-container {
    display: flex;
    justify-content: center;
    padding: 1.5rem 0;
    margin-top: 2rem;
  }

  .strava-badge {
    display: inline-block;
    background-color: #FC5200;
    color: #fff;
    padding: 5px 10px 5px 30px;
    font-size: 11px;
    font-family: Helvetica, Arial, sans-serif;
    white-space: nowrap;
    text-decoration: none;
    background-repeat: no-repeat;
    background-position: 10px center;
    border-radius: 3px;
    background-image: url('https://badges.strava.com/logo-strava-echelon.png');
  }

  .strava-badge:hover {
    opacity: 0.9;
  }

  .strava-logo {
    margin-left: 2px;
    vertical-align: text-bottom;
    height: 13px;
    width: 51px;
  }
</style>