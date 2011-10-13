/*
This file is part of OMOA.

(C) Leibniz Institute for Regional Geography,
    Leipzig, Germany

OMOA is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

OMOA is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with OMOA.  If not, see <http://www.gnu.org/licenses/>.
*/

package org.omoa.layer {

	import flash.display.DisplayObject;
	import flash.display.InteractiveObject;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	import org.omoa.event.SymbolEvent;
	import org.omoa.framework.ISpaceModel;
	import org.omoa.framework.ISpaceModelIterator;
	import org.omoa.framework.ISymbol;
	import org.omoa.spacemodel.BoundingBox;
	import org.omoa.spacemodel.SpaceModelEntity;
	
	[Event(name = SymbolEvent.CLICK, type = "org.omoa.event.SymbolEvent")]
	
	/**
	 * This layer visualizes a SpaceModel through one or more Symbols. 
	 * 
	 * @author Sebastian Specht
	 *
	 */

	public class SymbolLayer extends AbstractLayer {
		
		public var customIterator:ISpaceModelIterator;

		protected var _symbols:Vector.<ISymbol> = new Vector.<ISymbol>();
		
		private var layerSpriteToSymbol:Dictionary;
		private var symbolToSymbolSprite:Dictionary;
		private var symbolSpriteToEntityDictionary:Dictionary;
		
		private var SpaceModelEntityForSprite:Dictionary;
		
		private var entityDictionaries:Vector.<Dictionary>;

		public function SymbolLayer(id:String, spaceModel:ISpaceModel) {
			super(id, spaceModel);
			_type = "SymbolLayer";
			SpaceModelEntityForSprite = new Dictionary(true);
			layerSpriteToSymbol = new Dictionary(true);
			symbolSpriteToEntityDictionary = new Dictionary(true);
			entityDictionaries = new Vector.<Dictionary>();
		}

		public function addSymbol(symbol:ISymbol):void {
			if (!_isSetUp) {
				_symbols.push( symbol );
				if (symbol.interactive) {
					_interactive = true;
				}
			} else {
				throw new Error( "For now, you need to add Symbols before setup is executed. Sorry.");
			}
		}
		
		override public function setup(sprite:Sprite):void {
			var symbol:ISymbol;
			
			var symbolToSymbolSprite:Dictionary;
			var count:int;
			
			if (!_isSetUp) {
				sprite.mouseChildren = true;
				
				sprite.addEventListener(MouseEvent.CLICK, symbolRollOver );
				//sprite.addEventListener(MouseEvent.ROLL_OVER, symbolRollOver );
				//sprite.addEventListener(MouseEvent.ROLL_OUT, symbolRollOut );
				
				symbolToSymbolSprite = layerSpriteToSymbol[sprite] as Dictionary;
				if (!symbolToSymbolSprite) {
					// create a symbolToSymbolSprite Dictionary
					symbolToSymbolSprite = new Dictionary(true);
					layerSpriteToSymbol[sprite] = symbolToSymbolSprite;
				}
				
				var symbolCount:int = 0;
				for each (symbol in _symbols) {
					//TODO: This does not handle the dependance on a DataModel yet
					
					var symbolSprite:Sprite = symbolToSymbolSprite[symbol];
					if (!symbolSprite) {
						symbolSprite = new Sprite();
						symbolSprite.name = sprite.name + "_symbol_" + symbolCount;
						sprite.addChild( symbolSprite );
						symbolToSymbolSprite[symbol] = symbolSprite;
						
						if (symbol.needsInteractivity) { 
							symbolSprite.mouseChildren = true;
							symbolSprite.mouseEnabled = true;
						} else {
							symbolSprite.mouseChildren = false;
							symbolSprite.mouseEnabled = false;
						}
						
					}
					
					var entityToDisplayObjects:Dictionary = null;
					var displayObjectToEntity:Dictionary = null;
					
					
					// do the real symbol setup
					if (symbol.needsEntities) {
						// setup symbols with individual entites
						var displayObjectForEntity:DisplayObject;
						var spaceEntity:SpaceModelEntity;
						
						entityToDisplayObjects = new Dictionary(true);
						displayObjectToEntity = new Dictionary(true);
						
						// setup uses the standard-iterator of the SpaceModel, not the custom iterator.
						// TODO: introduce a dedicated Setup-Iterator? 
						var iterator:ISpaceModelIterator = _spaceModel.iterator();
						
						iterator.reset();
						
						while (iterator.hasNext()) {
							spaceEntity = iterator.next();
							displayObjectForEntity = symbol.setupEntity( symbolSprite, spaceEntity );
							
							entityToDisplayObjects[spaceEntity] = displayObjectForEntity;
							displayObjectToEntity[displayObjectForEntity] = spaceEntity;
							/*
							 * This ought to be managed by the symbols themself
							 */
							if (symbol.needsInteractivity) {
								// setup intetractivity for Sprites
								var entityAsSprite:Sprite = displayObjectForEntity as Sprite;
								if (entityAsSprite) {
									entityAsSprite.mouseEnabled = true;
									//entityAsSprite.addEventListener(MouseEvent.ROLL_OVER, symbolRollOver );
									//entityAsSprite.addEventListener(MouseEvent.ROLL_OUT, symbolRollOut );
								}
							}
							
						}
					}
					
					symbolSpriteToEntityDictionary[symbolSprite] = entityToDisplayObjects;
					
					symbolCount++;
					
				}
				_isSetUp = true;
			} else {
				trace( "setup called on a set-up layer" + this.id );
			}
		}
		
		override public function render(sprite:Sprite, displayExtent:Rectangle, viewportBounds:BoundingBox, transformation:Matrix):void {
			var iterator:ISpaceModelIterator;
			var spaceEntity:SpaceModelEntity;
			var symbol:ISymbol;
			
			if (customIterator) {
				iterator = customIterator;
			} else {
				iterator = _spaceModel.iterator();
			}
			
			var symbolToSymbolSprite:Dictionary = layerSpriteToSymbol[sprite] as Dictionary;
			for each (symbol in _symbols) {
				iterator.reset();
				trace( "render " + sprite.name + " " + symbol );
				var symbolSprite:Sprite = symbolToSymbolSprite[symbol];
				symbol.prepareRender(symbolSprite);
				
				if (symbol.needsEntities) {
					// render symbols with one DisplayObject per entity
					var entityDisplayObject:DisplayObject;
					var entityDictionary:Dictionary = symbolSpriteToEntityDictionary[symbolSprite];
					
					while (iterator.hasNext()) {
						spaceEntity = iterator.next();
						entityDisplayObject = entityDictionary[spaceEntity];
						symbol.render( entityDisplayObject, spaceEntity, transformation );
					}
				} else {
					// render symbols with one DisplayObject for all entites
					while (iterator.hasNext()) {
						spaceEntity = iterator.next();
						symbol.render( symbolSprite, spaceEntity, transformation );
					}
				}
				
				if (symbol.needsTransformation) {
					symbolSprite.transform.matrix = transformation;
				}
			}
		}
		
		override public function rescale(sprite:Sprite, displayExtent:Rectangle, viewportBounds:BoundingBox, transformation:Matrix):void {
			var iterator:ISpaceModelIterator;
			var spaceEntity:SpaceModelEntity;
			var symbol:ISymbol;
			//trace("RESCALE");
			if (customIterator) {
				iterator = customIterator;
			} else {
				iterator = _spaceModel.iterator();
			}
			
			for each (symbol in _symbols) {
				var symbolToSymbolSprite:Dictionary = layerSpriteToSymbol[sprite] as Dictionary;
				if (!symbolToSymbolSprite) {
					// TODO: This shouldn't happen: Setup hasn't been called yet. Bailing out.
					trace( "SymbolLayer.rescale(): ERROR, no Dictionary for Symbol existing." );
					break;
				}
				var symbolSprite:Sprite = symbolToSymbolSprite[symbol];
				
				if (!symbolSprite) {
					// TODO: This shouldn't happen: Setup hasn't been called yet. Bailing out.
					trace( "SymbolLayer.rescale(): ERROR, no Sprite for Symbol existing." );
					break;
				}
				
				if (symbol.needsTransformation) {
					symbolSprite.transform.matrix = transformation;
				}
				
				if (symbol.needsEntities) {
					// rescale symbols with one DisplayObject per entity
					var entityDisplayObject:DisplayObject;
					var entityDictionary:Dictionary = symbolSpriteToEntityDictionary[symbolSprite];	
					
					if (symbol.needsRescale) {
						iterator.reset();
						while (iterator.hasNext()) {
							spaceEntity = iterator.next();
							entityDisplayObject = entityDictionary[spaceEntity];
							symbol.rescale( entityDisplayObject, spaceEntity, displayExtent, viewportBounds, transformation );
						}
					}
				} else {
					// rescale symbols with one DisplayObject for all entites
					if (symbol.needsRescale) {
						iterator.reset();
						while (iterator.hasNext()) {
							spaceEntity = iterator.next();
							symbol.rescale( symbolSprite, spaceEntity, displayExtent, viewportBounds, transformation );
						}
					}
				}
			}
		}
		
		override public function recenter(sprite:Sprite, displayExtent:Rectangle, viewportBounds:BoundingBox, transformation:Matrix):void {
			var iterator:ISpaceModelIterator;
			var spaceEntity:SpaceModelEntity;
			var symbol:ISymbol;
			//trace("RECENTER");
			if (customIterator) {
				iterator = customIterator;
			} else {
				iterator = _spaceModel.iterator();
			}
			
			for each (symbol in _symbols) {
				//trace ( "     >>" + sprite.parent.parent.name + ">>"+ sprite.parent.name + ">>" + sprite.name );
				//trace( "     >>" + layerSpriteToSymbol[sprite]);
				var symbolToSymbolSprite:Dictionary = layerSpriteToSymbol[sprite] as Dictionary;
				var symbolSprite:Sprite = symbolToSymbolSprite[symbol];
				
				if (!symbolSprite) {
					// TODO: This shouldn't happen: Setup hasn't been called yet. Bailing out.
					trace( "SymbolLayer.rescale(): ERROR, no Sprite vor Symbol existing." );
					break;
				}
				
				if (symbol.needsTransformation) {
					symbolSprite.transform.matrix = transformation;
				}
				
				if (symbol.needsEntities) {
					// recenter symbols with one DisplayObject per entity
					var entityDisplayObject:DisplayObject;
					var entityDictionary:Dictionary = symbolSpriteToEntityDictionary[symbolSprite];
					
					if (symbol.needsRecenter) {
						iterator.reset();
						while (iterator.hasNext()) {
							spaceEntity = iterator.next();
							entityDisplayObject = entityDictionary[spaceEntity];
							symbol.recenter( entityDisplayObject, spaceEntity, displayExtent, viewportBounds, transformation );
						}
					}
				} else {
					// recenter symbols with one DisplayObject for all Entites
					if (symbol.needsRecenter) {
						iterator.reset();
						while (iterator.hasNext()) {
							spaceEntity = iterator.next();
							symbol.recenter( symbolSprite, spaceEntity, displayExtent, viewportBounds, transformation );
						}
					}
				}
			}

		}
		
		override public function cleanup(sprite:Sprite):void {
			throw new Error( "NOT IMPLEMENTED.");
		}
		
		public function getEntityForSprite( displayObject:DisplayObject ):SpaceModelEntity {
			return SpaceModelEntityForSprite[ displayObject ] as SpaceModelEntity;
		}
		
		public function getSymbolForSprite( displayObject:DisplayObject ):SpaceModelEntity {
			return null;
		}
		
		// connected to click
		private function symbolRollOver(e:MouseEvent):void {
			var sprite:Sprite = e.target as Sprite;
			if (sprite) {
				trace( "click " + sprite.name);
				//sprite.graphics.copyFrom( e.target as Sprite);
				//sprite.doubleClickEnabled = true;
				//sprite.buttonMode = true;
				
				//sprite.addEventListener(MouseEvent.CLICK, symbolClick );
				//sprite.addEventListener(MouseEvent.ROLL_OUT, spaceEntityRollOut );
			}
		}
		
		private function symbolRollOut(e:MouseEvent):void {
			var sprite:Sprite = e.target as Sprite;
			if (sprite) {
				//sprite.graphics.copyFrom( e.target as Sprite);
				
				//sprite.removeEventListener(MouseEvent.CLICK, symbolClick);
				//sprite.removeEventListener(MouseEvent.ROLL_OUT, spaceEntityRollOut );
				//sprite.doubleClickEnabled = false;
			}
		}
		
		private function symbolClick(e:MouseEvent):void {
			var se:SymbolEvent = new SymbolEvent( SymbolEvent.CLICK, e.bubbles, e.cancelable,
												e.localX, e.localY, e.target as InteractiveObject,
												e.ctrlKey, e.altKey, e.shiftKey, e.buttonDown, e.delta);
			
			// TODO: Broken.
			//se.entity = SpaceModelEntityForSprite[ e.target ] as SpaceModelEntity;
			
			if (e.target) {
				se.entity = spaceModel.findById(e.target.name);
			}
				
			//trace( se.entity );
			//trace( "Alt+Click (Selected) " + e.target.name );
			dispatchEvent( se );
			//e.stopImmediatePropagation();
		}
		
		public function set scalable(value:Boolean):void {
			_scalable = value;
		}

	}
}