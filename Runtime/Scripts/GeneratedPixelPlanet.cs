using System.Collections.Generic;
using UnityEngine;

namespace DeepFold.PixelPlanets {
	public abstract class GeneratedPixelPlanet: MonoBehaviour {
		[SerializeField]
		public int Pixel = 100;

		[SerializeField]
		public string Seed = "Seed";

		[SerializeField]
		public float CalcSeed;

		[SerializeField]
		public bool GenerateColors = false;

		public abstract void UpdatePlanetProperties();
	}
}
