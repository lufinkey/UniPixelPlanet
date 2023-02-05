using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

namespace DeepFold.PixelPlanets {
	[CustomEditor(typeof(GeneratedPixelPlanet), true)]
	public class GeneratedPixelPlanetEditor: Editor {
		public override void OnInspectorGUI() {
			DrawDefaultInspector();

			GeneratedPixelPlanet myScript = (GeneratedPixelPlanet)target;
			if (GUILayout.Button("Update")) {
				myScript.UpdatePlanetProperties();
			}
		}
	}
}
