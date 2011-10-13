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

package org.omoa.symbol {

	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.EventDispatcher;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import org.omoa.classification.AbstractClassification;
	import org.omoa.datamodel.DataDescription;
	import org.omoa.datamodel.DataModelDatum;
	import org.omoa.framework.ISymbol;
	import org.omoa.framework.ISymbolPropertyManipulator;
	import org.omoa.spacemodel.BoundingBox;
	import org.omoa.spacemodel.SpaceModelEntity;
	
	
	/**
	 * ...
	 * 
	 * @author Sebastian Specht
	 *
	 */

	public class AbstractSymbol extends EventDispatcher implements ISymbol {

		protected var _symbolProperties:Vector.<SymbolProperty>;
		protected var _dynamicProperties:Vector.<SymbolProperty> = new Vector.<SymbolProperty>();
		protected var _propertyNames:Array = new Array();
		protected var _propertyIndexes:Object = new Object();
		
		protected var _temporaryDatum:DataModelDatum;
		
		protected var _interactive:Boolean = false;
		protected var _entities:Boolean = false;
		protected var _transform:Boolean = true;
		protected var _recenter:Boolean = false;
		protected var _rescale:Boolean = false;


		public function AbstractSymbol() {
			for ( var i:int = 0; i < _symbolProperties.length; i++) {
				_propertyNames[i] = _symbolProperties[i].name;
				_propertyIndexes[_symbolProperties[i].name] = i;
			}
		}
		
		public function get needsEntities():Boolean {
			return _entities;
		}
		
		public function setupEntity(parentSprite:Sprite, spaceEntity:SpaceModelEntity):DisplayObject {
			return null;
		}
		
		public function get needsInteractivity():Boolean {
			return _interactive;
		}
		
		public function prepareRender(parentSprite:Sprite):void {
			
		}

		public function render(target:DisplayObject, spaceEntity:SpaceModelEntity, transformation:Matrix):void {
			updateDynamicProperties( spaceEntity );
			renderEntity(target, spaceEntity, transformation);
		}
		
		protected function updateValues( spaceEntity:SpaceModelEntity, property:SymbolProperty ):void {
			var property:SymbolProperty;
			var propertyDataDescription:DataDescription;
			var entityDataDescription:DataDescription;

			if (property.manipulator) {
				propertyDataDescription = property.manipulator.dataDescription;
				if (propertyDataDescription) {
					entityDataDescription = spaceEntity.getDataDescription( propertyDataDescription.model.id );
					//trace( spaceEntity.id + " and " + propertyDataDescription.model.id + " = " + entityDataDescription );
					if (entityDataDescription) {
						if (!property.datum) {
							property.datum = propertyDataDescription.model.getDatum( propertyDataDescription );
						}
						entityDataDescription.combine( property.datum.description, propertyDataDescription ); 
						entityDataDescription.model.updateDatum( property.datum );
						//trace( property.datum );
					} else {
						property.datum = null;
					}
				} else {
					property.datum = null;
				}
			} else {
				property.datum = null;
			}

		}
		
		protected function updateDynamicProperties( spaceEntity:SpaceModelEntity ):void {
			var property:SymbolProperty;
			var manipulator:ISymbolPropertyManipulator;
			var classification:AbstractClassification;
			
			for each (property in _dynamicProperties) {
				classification = property.manipulator as AbstractClassification;
				if (classification) {
					updateValues( spaceEntity, property );
					if (property.datum) {
						classification.selectElement( property.datum.value );
					} else {
						classification.selectElement( null );
					}
				} else {
					trace( "Keine Classification" );
				}
				setStaticProperty( property );
			}
		}
		
		protected function renderEntity(target:DisplayObject, spaceEntity:SpaceModelEntity, transformation:Matrix):void {
			throw new Error( "AbstractSymbol.renderEntity() needs to be implemented in Subclass" );
		}

		public function getPropertyNames():Array {
			return _propertyNames;
		}

		public function getProperty(propertyName:String):SymbolProperty {
			return _symbolProperties[_propertyIndexes[propertyName]];
		}

		public function setProperty(propertyName:String, manipulator:ISymbolPropertyManipulator):void {
			var property:SymbolProperty = _symbolProperties[_propertyIndexes[ propertyName ]];
			if (property) {
				property.manipulator = manipulator;
				if (manipulator.isDynamic) {
					if (_dynamicProperties.indexOf( property ) < 0) {
						_dynamicProperties.push( property );
					}
				} else {
					setStaticProperty( property );
				}
			}
		}
		
		public function get interactive():Boolean {
			return _interactive;
		}
		
		protected function setStaticProperty( property:SymbolProperty ):void {
			throw new Error( "AbstractSymbol.setStaticProperty() needs to be implemented in Subclass" );
		}
		
		public function get needsRescale():Boolean {
			return _rescale;
		}
		
		public function rescale(target:DisplayObject, spaceEntity:SpaceModelEntity, displayExtent:Rectangle, viewportBounds:BoundingBox, transformation:Matrix):void {
			if (_rescale) {
				throw new Error( "AbstractSymbol.rescale() needs to be implemented in Subclass" );
			}
		}
		
		public function get needsRecenter():Boolean {
			return _recenter;
		}
		
		public function recenter(target:DisplayObject, spaceEntity:SpaceModelEntity, displayExtent:Rectangle, viewportBounds:BoundingBox, transformation:Matrix):void {
			if (_recenter) {
				throw new Error( "AbstractSymbol.recenter() needs to be implemented in Subclass" );
			}
		}
		
		
		
		public function get needsTransformation():Boolean {
			return _transform;
		}
		
		override public function addEventListener(type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false):void 
		{
			super.addEventListener(type, listener, useCapture, priority, useWeakReference);
		}

	} // end class
} // end package