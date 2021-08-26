using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Jefford.TA {
	[Serializable]
	public class MeshVertexColor : ScriptableObject {

		[SerializeField]
		public Color[] _colors;
	}

}